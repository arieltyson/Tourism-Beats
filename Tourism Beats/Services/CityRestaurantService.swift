import CoreLocation
import Foundation
import MapKit
import OSLog

// MARK: - CityRestaurantService

private typealias RestaurantModels = CityRestaurantAPIModels

// MARK: - CityRestaurantService

actor CityRestaurantService: CityRestaurantProviding {
    static let shared = CityRestaurantService()

    private let session: URLSession
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityRestaurantService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 3

    private var memoryCache: [String: RestaurantModels.CachedPayload] = [:]

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func restaurants(for city: CityModel) async -> [CityRestaurant] {
        let key = Self.cacheKey(for: city)

        if let cached = self.memoryCache[key],
           cached.isValid(lifetime: self.cacheLifetime)
        {
            return cached.restaurants
        }

        let diskURL = self.diskCacheURL(for: city)

        if let cached = self.loadFromDisk(at: diskURL),
           cached.isValid(lifetime: self.cacheLifetime)
        {
            self.memoryCache[key] = cached
            return cached.restaurants
        }

        do {
            let restaurants = try await self.fetchRestaurants(for: city)
            let payload = RestaurantModels.CachedPayload(
                fetchedAt: .now,
                restaurants: restaurants
            )
            try? self.writeToDisk(payload, at: diskURL)
            self.memoryCache[key] = payload
            return restaurants
        } catch {
            self.logger.error(
                "Restaurant fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            if let stale = self.loadFromDisk(at: diskURL) {
                self.memoryCache[key] = stale
                return stale.restaurants
            }

            return []
        }
    }
}

// MARK: - Fetch Pipeline

extension CityRestaurantService {
    private func fetchRestaurants(for city: CityModel) async throws -> [CityRestaurant] {
        let mapKitResults = await Self.multiQueryMapKitSearch(for: city)

        var overpassCandidates: [RestaurantModels.OverpassRestaurant] = []
        do {
            overpassCandidates = try await self.fetchOverpassCandidates(for: city)
        } catch {
            self.logger.info(
                "Overpass enrichment unavailable: \(error.localizedDescription, privacy: .public)"
            )
        }

        var candidates: [CityRestaurantCandidate]

        if !mapKitResults.isEmpty {
            candidates = Self.mergeResults(
                mapKit: mapKitResults,
                overpass: overpassCandidates,
                cityName: city.name
            )
        } else if !overpassCandidates.isEmpty {
            self.logger.info(
                "MapKit unavailable, falling back to Overpass for \(city.name, privacy: .public)"
            )
            candidates = overpassCandidates.map(Self.candidate(from:))
        } else {
            throw RestaurantModels.ServiceError.invalidResponse
        }

        let wikidataMatches = await CityRestaurantWikidataService.fetchAwards(
            for: city,
            session: self.session
        )
        if !wikidataMatches.isEmpty {
            candidates = CityRestaurantWikidataService.enrichCandidates(
                candidates,
                with: wikidataMatches
            )
        }

        candidates = Self.tagDuplicateLocationCounts(candidates)

        return CityRestaurantRanking.topRestaurants(from: candidates, for: city, limit: 6)
    }

    private func fetchOverpassCandidates(
        for city: CityModel
    ) async throws -> [RestaurantModels.OverpassRestaurant] {
        let searchRadii = [8_000, 14_000]
        var candidates: [RestaurantModels.OverpassRestaurant] = []

        for radius in searchRadii {
            candidates = try await self.overpassRestaurants(
                latitude: city.coordinate.latitude,
                longitude: city.coordinate.longitude,
                cityName: city.name,
                radius: radius
            )

            if candidates.count >= 18 {
                break
            }
        }

        return candidates
    }
}

// MARK: - MapKit Search (Multi-Query Cross-Referencing)

extension CityRestaurantService {
    /// Pillar 1: Run multiple natural language queries against MapKit and
    /// track how many independent queries return each restaurant.
    /// Restaurants appearing across multiple queries are demonstrably popular.
    @MainActor
    private static func multiQueryMapKitSearch(
        for city: CityModel
    ) async -> [RestaurantModels.MapKitRestaurantResult] {
        let popularityQueries = [
            "restaurants",
            "best restaurants",
            "popular restaurants",
            "top rated restaurants"
        ]

        let foodQualityQueries = [
            "best food \(city.name)",
            "fine dining",
            "authentic local cuisine"
        ]

        var appearanceCounts: [String: Int] = [:]
        var foodQueryCounts: [String: Int] = [:]
        var bestResultByKey: [String: RestaurantModels.MapKitRestaurantResult] = [:]

        for query in popularityQueries {
            await self.accumulateResults(
                from: self.singleMapKitSearch(for: city, query: query),
                into: &bestResultByKey,
                appearanceCounts: &appearanceCounts
            )
        }

        for query in foodQualityQueries {
            let results = await self.singleMapKitSearch(for: city, query: query)
            self.accumulateResults(
                from: results,
                into: &bestResultByKey,
                appearanceCounts: &appearanceCounts
            )
            for result in results {
                let key = self.coordinateKey(
                    latitude: result.latitude,
                    longitude: result.longitude
                )
                foodQueryCounts[key, default: 0] += 1
            }
        }

        // Attach cross-query and food-query counts to each result
        return bestResultByKey.values.map { result in
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )
            return RestaurantModels.MapKitRestaurantResult(
                name: result.name,
                phoneNumber: result.phoneNumber,
                websiteURL: result.websiteURL,
                address: result.address,
                latitude: result.latitude,
                longitude: result.longitude,
                popularityRank: result.popularityRank,
                crossQueryAppearanceCount: appearanceCounts[key, default: 1],
                foodQueryAppearanceCount: foodQueryCounts[key, default: 0]
            )
        }
        .sorted { $0.popularityRank < $1.popularityRank }
    }

    @MainActor
    private static func accumulateResults(
        from results: [RestaurantModels.MapKitRestaurantResult],
        into bestResultByKey: inout [String: RestaurantModels.MapKitRestaurantResult],
        appearanceCounts: inout [String: Int]
    ) {
        for result in results {
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )

            appearanceCounts[key, default: 0] += 1

            if let existing = bestResultByKey[key] {
                if result.popularityRank < existing.popularityRank {
                    bestResultByKey[key] = result
                }
            } else {
                bestResultByKey[key] = result
            }
        }
    }

    @MainActor
    private static func singleMapKitSearch(
        for city: CityModel,
        query: String
    ) async -> [RestaurantModels.MapKitRestaurantResult] {
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: city.coordinate,
                latitudinalMeters: 10_000,
                longitudinalMeters: 10_000
            )
            request.resultTypes = .pointOfInterest
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])

            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            return response.mapItems.enumerated().compactMap { index, item in
                guard let name = item.name, !name.isEmpty else { return nil }

                let coordinate = item.location.coordinate
                return RestaurantModels.MapKitRestaurantResult(
                    name: name,
                    phoneNumber: item.phoneNumber,
                    websiteURL: item.url,
                    address: item.address?.shortAddress ?? item.address?.fullAddress,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    popularityRank: index + 1
                )
            }
        } catch {
            return []
        }
    }

    private static func coordinateKey(latitude: Double, longitude: Double) -> String {
        "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))"
    }

    private static func mergeResults(
        mapKit: [RestaurantModels.MapKitRestaurantResult],
        overpass: [RestaurantModels.OverpassRestaurant],
        cityName: String
    ) -> [CityRestaurantCandidate] {
        let normalizedCityName = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return mapKit.compactMap { mapItem in
            let normalizedName = mapItem.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard normalizedName != normalizedCityName,
                  !self.excludedKeywords.contains(where: {
                    normalizedName.localizedStandardContains($0)
                  })
            else {
                return nil
            }

            let overpassMatch = self.findOverpassMatch(for: mapItem, in: overpass)

            let coordinateKey = self.coordinateKey(
                latitude: mapItem.latitude,
                longitude: mapItem.longitude
            )

            // Pillar 3: Compute OSM metadata richness if we have an Overpass match
            let metadataScore = overpassMatch.map { self.metadataScore(for: $0) } ?? 0

            // Use OSM cuisine when available, otherwise infer from restaurant name
            let cuisine = overpassMatch?.cuisine ?? CuisineInferrer.infer(from: mapItem.name)

            return CityRestaurantCandidate(
                id: "mapkit-\(coordinateKey)",
                name: mapItem.name,
                cuisine: cuisine,
                address: mapItem.address ?? overpassMatch?.address,
                hours: overpassMatch?.openingHours,
                phoneNumber: mapItem.phoneNumber ?? overpassMatch?.phoneNumber,
                websiteURL: mapItem.websiteURL ?? overpassMatch?.website,
                sourceURL: self.sourceURL(
                    elementType: overpassMatch?.elementType,
                    elementIdentifier: overpassMatch?.elementIdentifier
                ),
                sourceName: overpassMatch != nil ? "Apple Maps + OpenStreetMap" : "Apple Maps",
                latitude: mapItem.latitude,
                longitude: mapItem.longitude,
                wheelchairAccessibility: overpassMatch?.wheelchairAccessibility ?? .unknown,
                offersVegetarianOptions: overpassMatch?.offersVegetarianOptions ?? false,
                offersVeganOptions: overpassMatch?.offersVeganOptions ?? false,
                hasOutdoorSeating: overpassMatch?.hasOutdoorSeating ?? false,
                acceptsReservations: overpassMatch?.acceptsReservations ?? false,
                isNotable: overpassMatch?.isNotable ?? false,
                brand: overpassMatch?.brand,
                popularityRank: mapItem.popularityRank,
                crossQueryAppearanceCount: mapItem.crossQueryAppearanceCount,
                foodQueryAppearanceCount: mapItem.foodQueryAppearanceCount,
                metadataRichnessScore: metadataScore,
                hasOSMStarRating: overpassMatch?.hasStarRating ?? false,
                isOrganic: overpassMatch?.isOrganic ?? false,
                dietaryVarietyCount: Self.dietaryVarietyCount(for: overpassMatch),
                hasBrandWikidata: overpassMatch?.hasBrandWikidata ?? false,
                hasOperator: overpassMatch?.hasOperator ?? false
            )
        }
    }

    private static func findOverpassMatch(
        for mapKitResult: RestaurantModels.MapKitRestaurantResult,
        in overpassResults: [RestaurantModels.OverpassRestaurant]
    ) -> RestaurantModels.OverpassRestaurant? {
        let normalizedMapName = mapKitResult.name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return overpassResults.first { overpassItem in
            let normalizedOverpassName = overpassItem.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            let nameMatches = normalizedMapName == normalizedOverpassName
                || normalizedMapName.localizedStandardContains(normalizedOverpassName)
                || normalizedOverpassName.localizedStandardContains(normalizedMapName)

            guard nameMatches else { return false }

            if let overpassLat = overpassItem.latitude,
               let overpassLon = overpassItem.longitude
            {
                let distance = CLLocation(
                    latitude: mapKitResult.latitude,
                    longitude: mapKitResult.longitude
                ).distance(from: CLLocation(latitude: overpassLat, longitude: overpassLon))
                return distance < 200
            }

            return true
        }
    }
}

// MARK: - Overpass

extension CityRestaurantService {
    private func overpassRestaurants(
        latitude: Double,
        longitude: Double,
        cityName: String,
        radius: Int
    ) async throws -> [RestaurantModels.OverpassRestaurant] {
        let query = Self.overpassQuery(
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )

        var components = URLComponents(string: "https://overpass-api.de/api/interpreter")
        components?.queryItems = [
            URLQueryItem(name: "data", value: query)
        ]

        guard let url = components?.url else {
            throw RestaurantModels.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url, timeout: 30)
        let response = try self.decoder.decode(RestaurantModels.OverpassResponse.self, from: data)
        return Self.processOverpassElements(response.elements, cityName: cityName)
    }

    private static func overpassQuery(
        latitude: Double,
        longitude: Double,
        radius: Int
    ) -> String {
        """
        [out:json][timeout:25];
        (
          nwr["amenity"="restaurant"]["name"](around:\(radius),\(latitude),\(longitude));
        );
        out center 120;
        """
    }

    private static func processOverpassElements(
        _ elements: [RestaurantModels.OverpassElement],
        cityName: String
    ) -> [RestaurantModels.OverpassRestaurant] {
        let normalizedCityName = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        var seen = Set<String>()
        var restaurants: [RestaurantModels.OverpassRestaurant] = []

        for element in elements {
            guard element.tags?.amenity == "restaurant",
                  let name = element.tags?.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty
            else {
                continue
            }

            let normalizedName = name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard normalizedName != normalizedCityName,
                  !self.excludedKeywords.contains(where: { normalizedName.localizedStandardContains($0) })
            else {
                continue
            }

            let latitude = element.lat ?? element.center?.lat
            let longitude = element.lon ?? element.center?.lon
            let coordinateKey = [
                latitude.map { String(Int(($0 * 10_000).rounded())) },
                longitude.map { String(Int(($0 * 10_000).rounded())) }
            ]
            .compactMap(\.self)
            .joined(separator: "|")

            let dedupeKey = "\(normalizedName)|\(coordinateKey)"
            guard !seen.contains(dedupeKey) else { continue }
            seen.insert(dedupeKey)

            restaurants.append(
                RestaurantModels.OverpassRestaurant(
                    elementType: element.type,
                    elementIdentifier: element.id,
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    cuisine: self.normalizedCuisine(from: element.tags?.cuisine),
                    website: self.normalizedURL(
                        primary: element.tags?.website,
                        fallback: element.tags?.contactWebsite
                    ),
                    phoneNumber: self.normalizedPhone(
                        primary: element.tags?.phone,
                        fallback: element.tags?.contactPhone
                    ),
                    openingHours: self.normalizedText(element.tags?.openingHours),
                    address: self.buildAddress(from: element.tags),
                    brand: self.normalizedText(element.tags?.brand),
                    wheelchairAccessibility: self.wheelchairAccessibility(from: element.tags?.wheelchair),
                    offersVegetarianOptions: self.booleanTag(element.tags?.dietVegetarian),
                    offersVeganOptions: self.booleanTag(element.tags?.dietVegan),
                    offersHalalOptions: self.booleanTag(element.tags?.dietHalal),
                    offersKosherOptions: self.booleanTag(element.tags?.dietKosher),
                    hasOutdoorSeating: self.booleanTag(element.tags?.outdoorSeating),
                    acceptsReservations: self.reservationsTag(element.tags?.reservation),
                    isNotable: self.normalizedText(element.tags?.wikidata) != nil,
                    isOrganic: self.booleanTag(element.tags?.organic),
                    hasStarRating: self.normalizedText(element.tags?.stars) != nil,
                    hasBrandWikidata: self.normalizedText(element.tags?.brandWikidata) != nil,
                    hasOperator: self.normalizedText(element.tags?.osmOperator) != nil
                )
            )
        }

        return restaurants.sorted { lhs, rhs in
            self.metadataScore(for: lhs) > self.metadataScore(for: rhs)
        }
    }

    private static func candidate(
        from restaurant: RestaurantModels.OverpassRestaurant
    ) -> CityRestaurantCandidate {
        CityRestaurantCandidate(
            id: "restaurant-\(restaurant.elementType ?? "osm")-\(restaurant.elementIdentifier ?? restaurant.name.hashValue)",
            name: restaurant.name,
            cuisine: restaurant.cuisine ?? CuisineInferrer.infer(from: restaurant.name),
            address: restaurant.address,
            hours: restaurant.openingHours,
            phoneNumber: restaurant.phoneNumber,
            websiteURL: restaurant.website,
            sourceURL: self.sourceURL(
                elementType: restaurant.elementType,
                elementIdentifier: restaurant.elementIdentifier
            ),
            sourceName: "OpenStreetMap",
            latitude: restaurant.latitude,
            longitude: restaurant.longitude,
            wheelchairAccessibility: restaurant.wheelchairAccessibility,
            offersVegetarianOptions: restaurant.offersVegetarianOptions,
            offersVeganOptions: restaurant.offersVeganOptions,
            hasOutdoorSeating: restaurant.hasOutdoorSeating,
            acceptsReservations: restaurant.acceptsReservations,
            isNotable: restaurant.isNotable,
            brand: restaurant.brand,
            popularityRank: nil,
            metadataRichnessScore: self.metadataScore(for: restaurant),
            hasOSMStarRating: restaurant.hasStarRating,
            isOrganic: restaurant.isOrganic,
            dietaryVarietyCount: self.dietaryVarietyCount(for: restaurant),
            hasBrandWikidata: restaurant.hasBrandWikidata,
            hasOperator: restaurant.hasOperator
        )
    }

    /// Detects chains by counting how many candidates share the same
    /// normalized name but appear at different coordinates.
    private static func tagDuplicateLocationCounts(
        _ candidates: [CityRestaurantCandidate]
    ) -> [CityRestaurantCandidate] {
        // Count occurrences of each normalized name
        var nameCounts: [String: Int] = [:]
        for candidate in candidates {
            let key = candidate.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
            nameCounts[key, default: 0] += 1
        }

        return candidates.map { candidate in
            let key = candidate.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
            let count = nameCounts[key, default: 1]
            guard count > 1 else { return candidate }
            var updated = candidate
            updated.duplicateLocationCount = count
            return updated
        }
    }

    private static func dietaryVarietyCount(
        for restaurant: RestaurantModels.OverpassRestaurant?
    ) -> Int {
        guard let restaurant else { return 0 }
        return [
            restaurant.offersVegetarianOptions,
            restaurant.offersVeganOptions,
            restaurant.offersHalalOptions,
            restaurant.offersKosherOptions
        ].filter(\.self).count
    }

    private static func metadataScore(for restaurant: RestaurantModels.OverpassRestaurant) -> Int {
        var score = 0
        if restaurant.website != nil { score += 6 }
        if restaurant.openingHours != nil { score += 5 }
        if restaurant.cuisine != nil { score += 4 }
        if restaurant.wheelchairAccessibility == .yes { score += 4 }
        if restaurant.address != nil { score += 2 }
        if restaurant.phoneNumber != nil { score += 2 }
        if restaurant.offersVegetarianOptions { score += 2 }
        if restaurant.offersVeganOptions { score += 2 }
        if restaurant.offersHalalOptions { score += 2 }
        if restaurant.offersKosherOptions { score += 2 }
        if restaurant.acceptsReservations { score += 2 }
        if restaurant.hasOutdoorSeating { score += 1 }
        if restaurant.isOrganic { score += 3 }
        if restaurant.hasStarRating { score += 8 }
        if restaurant.isNotable { score += 8 }
        return score
    }

    private static func normalizedCuisine(from value: String?) -> String? {
        guard let value else { return nil }

        let cuisines = value
            .split(separator: ";")
            .map { cuisine in
                cuisine
                    .replacingOccurrences(of: "_", with: " ")
                    .split(separator: " ")
                    .map { word in
                        word.prefix(1).uppercased() + word.dropFirst().lowercased()
                    }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        guard !cuisines.isEmpty else { return nil }
        return cuisines.prefix(2).joined(separator: " • ")
    }

    private static func normalizedURL(primary: String?, fallback: String?) -> URL? {
        let rawValue = [primary, fallback]
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first

        guard let rawValue else { return nil }

        let valueWithScheme = rawValue.contains("://") ? rawValue : "https://\(rawValue)"
        return URL(string: valueWithScheme, encodingInvalidCharacters: true)
    }

    private static func normalizedPhone(primary: String?, fallback: String?) -> String? {
        [primary, fallback]
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first
    }

    private static func buildAddress(
        from tags: RestaurantModels.OverpassTags?
    ) -> String? {
        guard let tags else { return nil }

        var parts: [String] = []

        if let street = self.normalizedText(tags.addrStreet) {
            if let number = self.normalizedText(tags.addrHousenumber) {
                parts.append("\(number) \(street)")
            } else {
                parts.append(street)
            }
        }

        if let city = self.normalizedText(tags.addrCity) {
            parts.append(city)
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private static func booleanTag(_ value: String?) -> Bool {
        guard let normalized = self.normalizedText(value)?.lowercased() else { return false }
        return ["yes", "only", "designated", "limited"].contains(normalized)
    }

    private static func reservationsTag(_ value: String?) -> Bool {
        guard let normalized = self.normalizedText(value)?.lowercased() else { return false }
        return normalized != "no"
    }

    private static func wheelchairAccessibility(
        from value: String?
    ) -> CityRestaurant.AccessibilityLevel {
        guard let normalized = self.normalizedText(value)?.lowercased() else {
            return .unknown
        }

        switch normalized {
        case "designated", "yes":
            return .yes
        case "limited":
            return .limited
        case "no":
            return .no
        default:
            return .unknown
        }
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func sourceURL(
        elementType: String?,
        elementIdentifier: Int?
    ) -> URL? {
        guard let elementType, let elementIdentifier else { return nil }
        return URL(
            string: "https://www.openstreetmap.org/\(elementType)/\(elementIdentifier)"
        )
    }

    private static let excludedKeywords = [
        "food court",
        "cafeteria",
        "canteen",
        "staff restaurant",
        "employee restaurant"
    ]
}

// MARK: - Networking

extension CityRestaurantService {
    private func fetchData(from url: URL, timeout: TimeInterval = 15) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = timeout
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-restaurants"))",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await self.session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RestaurantModels.ServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= http.statusCode else {
            throw RestaurantModels.ServiceError.httpStatus(http.statusCode)
        }

        return data
    }
}

// MARK: - Disk Cache

extension CityRestaurantService {
    private func loadFromDisk(at url: URL) -> RestaurantModels.CachedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? self.decoder.decode(RestaurantModels.CachedPayload.self, from: data)
    }

    private func writeToDisk(
        _ payload: RestaurantModels.CachedPayload,
        at url: URL
    ) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func diskCacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityRestaurants", directoryHint: .isDirectory)
            .appending(path: "\(Self.cacheKey(for: city)).json", directoryHint: .notDirectory)
    }

    private static func cacheKey(for city: CityModel) -> String {
        city.id
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")
    }
}
