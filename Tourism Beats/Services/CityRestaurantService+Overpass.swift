import CoreLocation
import Foundation
import MapKit
import OSLog

// MARK: - Overpass

extension CityRestaurantService {
    func overpassRestaurants(
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

        let data = try await self.overpassClient.data(for: query)
        let response = try self.decoder.decode(RestaurantModels.OverpassResponse.self, from: data)
        return Self.processOverpassElements(response.elements, cityName: cityName)
    }

    static func overpassQuery(
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

    static func processOverpassElements(
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
                self.overpassRestaurant(
                    from: element,
                    name: name,
                    latitude: latitude,
                    longitude: longitude
                )
            )
        }

        return restaurants.sorted { lhs, rhs in
            self.metadataScore(for: lhs) > self.metadataScore(for: rhs)
        }
    }

    private static func overpassRestaurant(
        from element: RestaurantModels.OverpassElement,
        name: String,
        latitude: Double?,
        longitude: Double?
    ) -> RestaurantModels.OverpassRestaurant {
        let tags = element.tags
        return RestaurantModels.OverpassRestaurant(
            elementType: element.type,
            elementIdentifier: element.id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            cuisine: self.normalizedCuisine(from: tags?.cuisine),
            website: self.normalizedURL(primary: tags?.website, fallback: tags?.contactWebsite),
            phoneNumber: self.normalizedPhone(primary: tags?.phone, fallback: tags?.contactPhone),
            openingHours: self.normalizedText(tags?.openingHours),
            address: self.buildAddress(from: tags),
            brand: self.normalizedText(tags?.brand),
            wheelchairAccessibility: self.wheelchairAccessibility(from: tags?.wheelchair),
            offersVegetarianOptions: self.booleanTag(tags?.dietVegetarian),
            offersVeganOptions: self.booleanTag(tags?.dietVegan),
            offersHalalOptions: self.booleanTag(tags?.dietHalal),
            offersKosherOptions: self.booleanTag(tags?.dietKosher),
            hasOutdoorSeating: self.booleanTag(tags?.outdoorSeating),
            acceptsReservations: self.reservationsTag(tags?.reservation),
            isNotable: self.normalizedText(tags?.wikidata) != nil,
            isOrganic: self.booleanTag(tags?.organic),
            hasStarRating: self.normalizedText(tags?.stars) != nil,
            hasBrandWikidata: self.normalizedText(tags?.brandWikidata) != nil,
            hasOperator: self.normalizedText(tags?.osmOperator) != nil
        )
    }

    static func candidate(
        from restaurant: RestaurantModels.OverpassRestaurant
    ) -> CityRestaurantCandidate {
        CityRestaurantCandidate(
            id: "restaurant-\(restaurant.elementType ?? "osm")-\(restaurant.elementIdentifier ?? restaurant.name.hashValue)",
            name: restaurant.name,
            cuisine: restaurant.cuisine
                ?? CuisineInferrer.infer(from: restaurant.name),
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

    static func tagDuplicateLocationCounts(
        _ candidates: [CityRestaurantCandidate]
    ) -> [CityRestaurantCandidate] {
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

    // MARK: - Wider-Radius Chain Scan

    func detectChainsFromWiderScan(
        for city: CityModel
    ) async -> Set<String> {
        let query = """
        [out:json][timeout:15];
        nwr["amenity"="restaurant"]["name"](around:25000,\(city.coordinate.latitude),\(city.coordinate.longitude));
        out center 500;
        """

        do {
            let data = try await self.overpassClient.data(for: query)
            let response = try self.decoder.decode(RestaurantModels.OverpassResponse.self, from: data)

            let entries = response.elements.compactMap { element
                -> CityRestaurantChainDetector.RestaurantNameEntry? in
                guard let name = element.tags?.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !name.isEmpty
                else { return nil }
                let lat = element.lat ?? element.center?.lat
                let lon = element.lon ?? element.center?.lon
                return .init(name: name, latitude: lat, longitude: lon)
            }

            return CityRestaurantChainDetector.detectChainSignatures(from: entries)
        } catch {
            self.logger.info(
                "Chain scan unavailable: \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    static func applyChainSignatures(
        _ signatures: Set<String>,
        to candidates: [CityRestaurantCandidate]
    ) -> [CityRestaurantCandidate] {
        candidates.map { candidate in
            let normalized = candidate.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard CityRestaurantChainDetector.matchesChainSignature(
                normalized, in: signatures
            ) else { return candidate }

            var updated = candidate
            updated.duplicateLocationCount = max(updated.duplicateLocationCount, 3)
            return updated
        }
    }

    static func dietaryVarietyCount(
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

    static func metadataScore(for restaurant: RestaurantModels.OverpassRestaurant) -> Int {
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

    static func normalizedCuisine(from value: String?) -> String? {
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

    static func normalizedURL(primary: String?, fallback: String?) -> URL? {
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

    static func normalizedPhone(primary: String?, fallback: String?) -> String? {
        [primary, fallback]
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first
    }

    static func buildAddress(
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

    static func booleanTag(_ value: String?) -> Bool {
        guard let normalized = self.normalizedText(value)?.lowercased() else { return false }
        return ["yes", "only", "designated", "limited"].contains(normalized)
    }

    static func reservationsTag(_ value: String?) -> Bool {
        guard let normalized = self.normalizedText(value)?.lowercased() else { return false }
        return normalized != "no"
    }

    static func wheelchairAccessibility(
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

    static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func sourceURL(
        elementType: String?,
        elementIdentifier: Int?
    ) -> URL? {
        guard let elementType, let elementIdentifier else { return nil }
        return URL(
            string: "https://www.openstreetmap.org/\(elementType)/\(elementIdentifier)"
        )
    }

    static let excludedKeywords = [
        "food court",
        "cafeteria",
        "canteen",
        "staff restaurant",
        "employee restaurant"
    ]
}
