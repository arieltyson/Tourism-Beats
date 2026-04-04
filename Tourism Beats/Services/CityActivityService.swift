import Foundation
import OSLog

// MARK: - CityActivityService

typealias Models = CityActivityAPIModels

// MARK: - CityActivityService

actor CityActivityService: CityActivityProviding {
    static let shared = CityActivityService()
    private static let cacheVersion = "v3"
    private static let desiredActivityCount = 6
    private static let sourceCandidateCount = 18

    let session: URLSession
    private let wikivoyageParser = WikivoyageActivityGuideParser()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityActivityService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 14

    private var memoryCache: [String: Models.CachedPayload] = [:]

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

    func activities(for city: CityModel) async -> [CityActivity] {
        let key = Self.cacheKey(for: city)

        if let cached = self.memoryCache[key],
           cached.isValid(lifetime: self.cacheLifetime)
        {
            return cached.activities
        }

        let diskURL = self.diskCacheURL(for: city)

        if let cached = self.loadFromDisk(at: diskURL),
           cached.isValid(lifetime: self.cacheLifetime)
        {
            self.memoryCache[key] = cached
            return cached.activities
        }

        let activities = await self.fetchActivities(for: city)
        guard !activities.isEmpty else {
            if let stale = self.loadFromDisk(at: diskURL) {
                self.memoryCache[key] = stale
                return stale.activities
            }

            return []
        }

        let payload = Models.CachedPayload(fetchedAt: .now, activities: activities)
        try? self.writeToDisk(payload, at: diskURL)
        self.memoryCache[key] = payload
        return activities
    }
}

// MARK: - Fetch Pipeline (Overpass → Wikivoyage → Wikipedia)

extension CityActivityService {
    private func fetchActivities(for city: CityModel) async -> [CityActivity] {
        var collectedActivities: [CityActivity] = []

        let overpassActivities = await self.overpassActivities(for: city)
        collectedActivities += overpassActivities

        if CityActivityRanking.topActivities(
            from: collectedActivities,
            for: city,
            limit: Self.desiredActivityCount
        ).count < Self.desiredActivityCount {
            let wikivoyageActivities = await self.wikivoyageActivities(for: city)
            collectedActivities += wikivoyageActivities
        }

        if CityActivityRanking.topActivities(
            from: collectedActivities,
            for: city,
            limit: Self.desiredActivityCount
        ).count < Self.desiredActivityCount {
            let wikipediaActivities = await self.wikipediaFallbackActivities(for: city)
            collectedActivities += wikipediaActivities
        }

        let mapKitResults = await Self.multiQueryMapKitSearch(for: city)
        let mapKitActivities = Self.mapKitActivities(
            for: city,
            results: mapKitResults,
            existingActivities: collectedActivities
        )
        collectedActivities += mapKitActivities

        let demandSignals = await self.demandSignals(
            for: collectedActivities,
            mapKitResults: mapKitResults
        )

        return CityActivityRanking.topActivities(
            from: collectedActivities,
            for: city,
            demandSignals: demandSignals,
            limit: Self.desiredActivityCount
        )
    }

    private func overpassActivities(for city: CityModel) async -> [CityActivity] {
        do {
            let pois = try await self.overpassPOIs(
                latitude: city.coordinate.latitude,
                longitude: city.coordinate.longitude,
                cityName: city.name
            )

            guard !pois.isEmpty else {
                self.logger.info(
                    "No Overpass POIs for \(city.name, privacy: .public)"
                )
                return []
            }

            let topPOIs = Array(pois.prefix(12))
            let enriched = await self.enrichWithWikipedia(pois: topPOIs)
            let withImages = await self.resolveWikidataImages(for: enriched)
            return Array(withImages.prefix(Self.sourceCandidateCount))
        } catch {
            self.logger.error(
                "Overpass activity fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func wikipediaFallbackActivities(for city: CityModel) async -> [CityActivity] {
        do {
            return try await self.fallbackWikipediaActivities(for: city)
        } catch {
            self.logger.error(
                "Wikipedia activity fallback failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func fallbackWikipediaActivities(for city: CityModel) async throws -> [CityActivity] {
        let geoResults = try await self.wikiGeoSearch(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude
        )

        let candidates = Self.filterGeoResults(geoResults, cityName: city.name)
        guard !candidates.isEmpty else { return [] }

        let titles = candidates.prefix(20).map(\.title)
        let pages = try await self.wikiPageDetails(for: Array(titles))
        let ranked = Self.rankPages(pages)
        let activities = Array(ranked.prefix(Self.sourceCandidateCount)).map {
            Self.mapPageToActivity(page: $0)
        }

        return await self.resolveWikidataImages(for: activities)
    }
}

// MARK: - Overpass API (OpenStreetMap)

extension CityActivityService {
    private func overpassPOIs(
        latitude: Double,
        longitude: Double,
        cityName: String
    ) async throws -> [Models.OverpassPOI] {
        let radius = 12_000
        let query = Self.overpassQuery(latitude: latitude, longitude: longitude, radius: radius)

        var components = URLComponents(string: "https://overpass-api.de/api/interpreter")
        components?.queryItems = [URLQueryItem(name: "data", value: query)]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url, timeout: 25)
        let response = try self.decoder.decode(Models.OverpassResponse.self, from: data)

        return Self.processOverpassElements(response.elements, cityName: cityName)
    }

    private static func overpassQuery(latitude: Double, longitude: Double, radius: Int) -> String {
        """
        [out:json][timeout:20];
        (
          nwr["tourism"~"attraction|museum|gallery|artwork|viewpoint|zoo|aquarium|theme_park"]\
        (around:\(radius),\(latitude),\(longitude));
          nwr["historic"~"monument|memorial|castle|ruins|fort|archaeological_site|palace|city_gate"]\
        (around:\(radius),\(latitude),\(longitude));
          nwr["leisure"~"park|garden|nature_reserve|stadium"]\
        (around:\(radius),\(latitude),\(longitude))["name"];
          nwr["amenity"~"theatre|place_of_worship"]\
        (around:\(radius),\(latitude),\(longitude))["name"]["wikidata"];
        );
        out center 60;
        """
    }

    private static func processOverpassElements(
        _ elements: [Models.OverpassElement],
        cityName: String
    ) -> [Models.OverpassPOI] {
        let cityNormalized = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        var seen = Set<String>()
        var pois: [Models.OverpassPOI] = []

        for element in elements {
            guard let name = element.tags?.name, !name.isEmpty else { continue }

            let nameNormalized = name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard nameNormalized != cityNormalized,
                  !seen.contains(nameNormalized),
                  !self.excludedKeywords.contains(where: { nameNormalized.localizedStandardContains($0) })
            else { continue }

            seen.insert(nameNormalized)

            pois.append(Models.OverpassPOI(
                name: name,
                latitude: element.lat ?? element.center?.lat,
                longitude: element.lon ?? element.center?.lon,
                tourism: element.tags?.tourism,
                historic: element.tags?.historic,
                leisure: element.tags?.leisure,
                amenity: element.tags?.amenity,
                wikipedia: element.tags?.wikipedia,
                wikidata: element.tags?.wikidata,
                website: element.tags?.website,
                openingHours: element.tags?.openingHours,
                fee: element.tags?.fee,
                address: self.buildAddress(from: element.tags)
            ))
        }

        return pois.sorted { self.notabilityScore($0) > self.notabilityScore($1) }
    }

    private static func notabilityScore(_ poi: Models.OverpassPOI) -> Int {
        var score = 0
        if poi.wikipedia != nil { score += 10 }
        if poi.wikidata != nil { score += 5 }
        if poi.website != nil { score += 2 }
        if poi.tourism == "museum" { score += 8 }
        if poi.tourism == "attraction" { score += 7 }
        if poi.historic == "castle" || poi.historic == "palace" { score += 7 }
        if poi.tourism == "gallery" { score += 6 }
        if poi.tourism == "zoo" || poi.tourism == "aquarium" { score += 6 }
        if poi.historic == "monument" || poi.historic == "memorial" { score += 5 }
        if poi.tourism == "viewpoint" { score += 4 }
        if poi.amenity == "theatre" { score += 4 }
        if poi.leisure == "park" || poi.leisure == "garden" { score += 3 }
        if poi.leisure == "stadium" { score += 3 }
        if poi.amenity == "place_of_worship" { score += 3 }
        return score
    }

    private static func buildAddress(from tags: Models.OverpassTags?) -> String? {
        guard let tags else { return nil }
        var parts: [String] = []
        if let street = tags.addrStreet {
            if let number = tags.addrHousenumber {
                parts.append("\(number) \(street)")
            } else {
                parts.append(street)
            }
        }
        if let city = tags.addrCity { parts.append(city) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    static let excludedKeywords = [
        "district", "neighborhood", "neighbourhood", "county",
        "school", "university", "college", "hospital",
        "cemetery", "freeway", "highway", "route ",
        "interchange", "census", "election", "demographic",
        "parking", "toilet", "recycling"
    ]
}

// MARK: - Wikipedia Enrichment

extension CityActivityService {
    private func enrichWithWikipedia(pois: [Models.OverpassPOI]) async -> [CityActivity] {
        let wikiTitles: [(Int, String)] = pois.enumerated().compactMap { index, poi in
            if let wiki = poi.wikipedia, wiki.hasPrefix("en:") {
                return (index, String(wiki.dropFirst(3)))
            }
            return (index, poi.name)
        }

        let titleStrings = wikiTitles.map(\.1)
        var allPages: [String: Models.WikiPageDetail] = [:]

        for batch in stride(from: 0, to: titleStrings.count, by: 20) {
            let batchTitles = Array(titleStrings[batch ..< min(batch + 20, titleStrings.count)])
            if let pages = try? await self.wikiPageDetails(for: batchTitles) {
                for page in pages {
                    allPages[page.title.lowercased()] = page
                }
            }
        }

        return pois.enumerated().map { index, poi in
            let searchTitle = wikiTitles.first { $0.0 == index }?.1 ?? poi.name
            let page = allPages[searchTitle.lowercased()] ?? allPages[poi.name.lowercased()]
            return Self.mapPOIToActivity(poi: poi, page: page)
        }
    }

    private static func mapPOIToActivity(
        poi: Models.OverpassPOI,
        page: Models.WikiPageDetail?
    ) -> CityActivity {
        let result = Models.categoryFromPOI(poi: poi)

        let imageURL: URL? = if let source = page?.original?.source {
            URL(string: source)
        } else if let source = page?.thumbnail?.source {
            URL(string: source)
        } else {
            nil
        }

        let summary = if let extract = page?.extract, !extract.isEmpty {
            Self.cleanExtract(extract)
        } else {
            "A notable \(result.category.lowercased()) worth visiting."
        }

        let encodedName = (page?.title ?? poi.name)
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? poi.name

        let sourceURL: URL? = if page != nil {
            URL(string: "https://en.wikipedia.org/wiki/\(encodedName)", encodingInvalidCharacters: true)
        } else {
            nil
        }

        let officialURL: URL? = if let website = poi.website {
            URL(string: website, encodingInvalidCharacters: true)
        } else {
            nil
        }

        return CityActivity(
            id: "osm-\(page?.pageid ?? poi.name.hashValue)",
            name: poi.name,
            summary: summary,
            category: result.category,
            kind: result.kind,
            imageURL: imageURL,
            officialURL: officialURL,
            sourceURL: sourceURL,
            sourceName: "OpenStreetMap",
            hours: poi.openingHours,
            price: poi.fee == "yes" ? "Paid admission" : (poi.fee == "no" ? "Free" : nil),
            address: poi.address,
            directions: nil,
            timingTip: nil,
            latitude: poi.latitude,
            longitude: poi.longitude,
            wikidataIdentifier: poi.wikidata ?? page?.pageprops?.wikidataItem,
            sourcePageTitle: page?.title,
            sourceAnchor: nil
        )
    }
}

// MARK: - Wikipedia GeoSearch Fallback

extension CityActivityService {
    private func wikiGeoSearch(
        latitude: Double,
        longitude: Double
    ) async throws -> [Models.GeoSearchResult] {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "geosearch"),
            URLQueryItem(name: "gscoord", value: "\(latitude)|\(longitude)"),
            URLQueryItem(name: "gsradius", value: "15000"),
            URLQueryItem(name: "gslimit", value: "50"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(Models.GeoSearchResponse.self, from: data)
        return response.query?.geosearch ?? []
    }

    private func wikiPageDetails(
        for titles: [String]
    ) async throws -> [Models.WikiPageDetail] {
        guard !titles.isEmpty else { return [] }

        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "titles", value: titles.joined(separator: "|")),
            URLQueryItem(name: "prop", value: "extracts|pageimages|coordinates|pageprops"),
            URLQueryItem(name: "exintro", value: "1"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "exlimit", value: "\(titles.count)"),
            URLQueryItem(name: "piprop", value: "original|thumbnail"),
            URLQueryItem(name: "pithumbsize", value: "800"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(Models.WikiPageQueryResponse.self, from: data)
        return response.query?.pages ?? []
    }

    private static func filterGeoResults(
        _ results: [Models.GeoSearchResult],
        cityName: String
    ) -> [Models.GeoSearchResult] {
        let cityNormalized = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return results.filter { result in
            let titleNormalized = result.title.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            guard titleNormalized != cityNormalized else { return false }
            return !self.excludedKeywords.contains(where: { titleNormalized.localizedStandardContains($0) })
        }
    }

    private static func rankPages(_ pages: [Models.WikiPageDetail]) -> [Models.WikiPageDetail] {
        pages
            .filter { ($0.extract?.count ?? 0) >= 80 }
            .sorted { lhs, rhs in
                let lhsImage = lhs.thumbnail != nil || lhs.original != nil
                let rhsImage = rhs.thumbnail != nil || rhs.original != nil
                if lhsImage != rhsImage { return lhsImage }
                return (lhs.extract?.count ?? 0) > (rhs.extract?.count ?? 0)
            }
    }

    private static func mapPageToActivity(page: Models.WikiPageDetail) -> CityActivity {
        let result = Models.categoryFromText(title: page.title, extract: page.extract ?? "")

        let imageURL: URL? = if let source = page.original?.source {
            URL(string: source)
        } else if let source = page.thumbnail?.source {
            URL(string: source)
        } else {
            nil
        }

        let encodedTitle = page.title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? page.title

        return CityActivity(
            id: "wiki-\(page.pageid)",
            name: page.title,
            summary: self.cleanExtract(page.extract ?? ""),
            category: result.category,
            kind: result.kind,
            imageURL: imageURL,
            officialURL: nil,
            sourceURL: URL(string: "https://en.wikipedia.org/wiki/\(encodedTitle)", encodingInvalidCharacters: true),
            sourceName: "Wikipedia",
            hours: nil,
            price: nil,
            address: nil,
            directions: nil,
            timingTip: nil,
            latitude: page.coordinates?.first?.lat,
            longitude: page.coordinates?.first?.lon,
            wikidataIdentifier: page.pageprops?.wikidataItem,
            sourcePageTitle: page.title,
            sourceAnchor: nil
        )
    }

    private static func cleanExtract(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s*==.*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Wikivoyage Guide Fallback

extension CityActivityService {
    private func wikivoyageActivities(for city: CityModel) async -> [CityActivity] {
        do {
            guard let guidePageTitle = try await self.wikivoyageGuidePageTitle(for: city) else {
                return []
            }

            let tocSections = try await self.wikivoyageTOCSections(for: guidePageTitle)
            let activitySections = Self.wikivoyageActivitySections(from: tocSections)
            guard !activitySections.isEmpty else { return [] }

            var parsedActivities: [CityActivity] = []

            for section in activitySections {
                let wikitext = try await self.wikivoyageSectionWikitext(
                    for: guidePageTitle,
                    sectionIndex: section.index
                )

                parsedActivities += self.wikivoyageParser.activities(
                    from: wikitext,
                    guidePageTitle: guidePageTitle,
                    topSectionTitle: section.line
                )
            }

            guard !parsedActivities.isEmpty else { return [] }

            let withImages = await self.resolveWikidataImages(for: parsedActivities)
            return Array(withImages.prefix(Self.sourceCandidateCount))
        } catch {
            self.logger.error(
                "Wikivoyage activity fallback failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func wikivoyageGuidePageTitle(for city: CityModel) async throws -> String? {
        let results = try await self.wikivoyageGeoSearch(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude
        )

        if let bestTitle = Self.bestWikivoyageGuideTitle(
            from: results,
            cityName: city.name
        ) {
            return bestTitle
        }

        return city.name
    }

    private func wikivoyageGeoSearch(
        latitude: Double,
        longitude: Double
    ) async throws -> [Models.GeoSearchResult] {
        var components = URLComponents(string: "https://en.wikivoyage.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "geosearch"),
            URLQueryItem(name: "gscoord", value: "\(latitude)|\(longitude)"),
            URLQueryItem(name: "gsradius", value: "20000"),
            URLQueryItem(name: "gslimit", value: "20"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(Models.GeoSearchResponse.self, from: data)
        return response.query?.geosearch ?? []
    }

    private func wikivoyageTOCSections(
        for pageTitle: String
    ) async throws -> [Models.WikimediaTOCSection] {
        var components = URLComponents(string: "https://en.wikivoyage.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: pageTitle),
            URLQueryItem(name: "prop", value: "tocdata"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(Models.WikimediaParseResponse.self, from: data)

        if response.error != nil {
            throw Models.ServiceError.invalidResponse
        }

        return response.parse?.tocdata?.sections ?? []
    }

    private func wikivoyageSectionWikitext(
        for pageTitle: String,
        sectionIndex: String
    ) async throws -> String {
        var components = URLComponents(string: "https://en.wikivoyage.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: pageTitle),
            URLQueryItem(name: "prop", value: "wikitext"),
            URLQueryItem(name: "section", value: sectionIndex),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw Models.ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(Models.WikimediaParseResponse.self, from: data)

        if response.error != nil {
            throw Models.ServiceError.invalidResponse
        }

        return response.parse?.wikitext ?? ""
    }

    private static func bestWikivoyageGuideTitle(
        from results: [Models.GeoSearchResult],
        cityName: String
    ) -> String? {
        let normalizedCityName = Self.normalizedGuideTitle(cityName)

        let rankedResults = results.sorted { lhs, rhs in
            let lhsScore = Self.guideTitleScore(lhs.title, cityName: normalizedCityName)
            let rhsScore = Self.guideTitleScore(rhs.title, cityName: normalizedCityName)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return lhs.dist < rhs.dist
        }

        return rankedResults.first?.title
    }

    private static func guideTitleScore(_ title: String, cityName: String) -> Int {
        let normalizedTitle = Self.normalizedGuideTitle(title)
        var score = 0

        if normalizedTitle == cityName { score += 100 }
        if normalizedTitle.hasPrefix("\(cityName) ") { score += 40 }
        if !title.contains("/") { score += 25 }
        if normalizedTitle.localizedStandardContains(cityName) { score += 20 }
        if title.contains("/") { score -= 20 }

        return score
    }

    private static func normalizedGuideTitle(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: " ")
            .lowercased()
    }

    private static func wikivoyageActivitySections(
        from sections: [Models.WikimediaTOCSection]
    ) -> [Models.WikimediaTOCSection] {
        sections.filter {
            $0.tocLevel == 1
                && ($0.line.localizedStandardContains("see")
                        || $0.line.localizedStandardContains("do")
                )
        }
    }
}

// MARK: - Wikidata Image Resolution

extension CityActivityService {
    private func resolveWikidataImages(for activities: [CityActivity]) async -> [CityActivity] {
        let needsImage = activities.filter { $0.imageURL == nil && $0.wikidataIdentifier != nil }
        guard !needsImage.isEmpty else { return activities }

        let ids = needsImage.compactMap(\.wikidataIdentifier)
        let imageMap = await self.wikidataImageMap(for: ids)
        guard !imageMap.isEmpty else { return activities }

        return activities.map { activity in
            guard activity.imageURL == nil,
                  let qid = activity.wikidataIdentifier,
                  let resolvedURL = imageMap[qid]
            else { return activity }

            return CityActivity(
                id: activity.id,
                name: activity.name,
                summary: activity.summary,
                category: activity.category,
                kind: activity.kind,
                imageURL: resolvedURL,
                officialURL: activity.officialURL,
                sourceURL: activity.sourceURL,
                sourceName: activity.sourceName,
                hours: activity.hours,
                price: activity.price,
                address: activity.address,
                directions: activity.directions,
                timingTip: activity.timingTip,
                latitude: activity.latitude,
                longitude: activity.longitude,
                wikidataIdentifier: activity.wikidataIdentifier,
                sourcePageTitle: activity.sourcePageTitle,
                sourceAnchor: activity.sourceAnchor
            )
        }
    }

    private func wikidataImageMap(for ids: [String]) async -> [String: URL] {
        let joined = Array(ids.prefix(50)).joined(separator: "|")

        var components = URLComponents(string: "https://www.wikidata.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: joined),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else { return [:] }

        do {
            let data = try await self.fetchData(from: url)
            let response = try self.decoder.decode(Models.WikidataEntitiesResponse.self, from: data)

            var map: [String: URL] = [:]
            for (qid, entity) in response.entities {
                guard let claims = entity.claims?["P18"],
                      let firstClaim = claims.first,
                      let fileName = firstClaim.mainsnak.datavalue?.value.stringValue
                else { continue }

                let encoded = fileName
                    .replacingOccurrences(of: " ", with: "_")
                    .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

                if !encoded.isEmpty,
                   let imageURL = URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)")
                {
                    map[qid] = imageURL
                }
            }
            return map
        } catch {
            self.logger.debug("Wikidata image fetch failed: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }
}

// MARK: - Networking

extension CityActivityService {
    private func fetchData(from url: URL, timeout: TimeInterval = 15) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = timeout
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-activities"))",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await self.session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Models.ServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= http.statusCode else {
            throw Models.ServiceError.httpStatus(http.statusCode)
        }

        return data
    }
}

// MARK: - Disk Cache

extension CityActivityService {
    private func loadFromDisk(at url: URL) -> Models.CachedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? self.decoder.decode(Models.CachedPayload.self, from: data)
    }

    private func writeToDisk(_ payload: Models.CachedPayload, at url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func diskCacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityActivities", directoryHint: .isDirectory)
            .appending(path: "\(Self.cacheKey(for: city)).json", directoryHint: .notDirectory)
    }

    private static func cacheKey(for city: CityModel) -> String {
        let normalizedCityIdentifier = city.id
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")

        return "\(Self.cacheVersion)_\(normalizedCityIdentifier)"
    }
}
