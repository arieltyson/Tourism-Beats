import Foundation
import OSLog

// MARK: - CityActivityService

actor CityActivityService: CityActivityProviding {
    static let shared = CityActivityService()

    private let session: URLSession
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityActivityService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 14

    private var memoryCache: [String: CachedPayload] = [:]

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

        do {
            let activities = try await self.fetchActivities(for: city)
            let payload = CachedPayload(fetchedAt: .now, activities: activities)
            try? self.writeToDisk(payload, at: diskURL)
            self.memoryCache[key] = payload
            return activities
        } catch {
            self.logger.error(
                "Activity fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            if let stale = self.loadFromDisk(at: diskURL) {
                self.memoryCache[key] = stale
                return stale.activities
            }

            return []
        }
    }
}

// MARK: - Wikipedia Fetch Pipeline

extension CityActivityService {
    private func fetchActivities(for city: CityModel) async throws -> [CityActivity] {
        let geoResults = try await self.geoSearch(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude
        )

        let candidates = Self.filterGeoResults(geoResults, cityName: city.name)
        guard !candidates.isEmpty else { return [] }

        let titles = candidates.prefix(20).map(\.title)
        let pages = try await self.pageDetails(for: Array(titles))

        let ranked = Self.rankPages(pages)
        let topPages = Array(ranked.prefix(6))

        let activities = topPages.map { page in
            Self.mapToActivity(page: page)
        }

        return await self.resolveWikidataImages(for: activities)
    }

    private static func filterGeoResults(
        _ results: [GeoSearchResult],
        cityName: String
    ) -> [GeoSearchResult] {
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

            for excluded in Self.excludedTitleKeywords {
                if titleNormalized.localizedStandardContains(excluded) {
                    return false
                }
            }

            return true
        }
    }

    private static let excludedTitleKeywords = [
        "district", "neighborhood", "neighbourhood", "county",
        "school", "university", "college", "hospital",
        "cemetery", "freeway", "highway", "route ",
        "interchange", "census", "election", "demographic"
    ]

    private static func rankPages(_ pages: [PageDetail]) -> [PageDetail] {
        pages
            .filter { ($0.extract?.count ?? 0) >= 80 }
            .sorted { lhs, rhs in
                let lhsImage = lhs.thumbnail != nil || lhs.original != nil
                let rhsImage = rhs.thumbnail != nil || rhs.original != nil
                if lhsImage != rhsImage { return lhsImage }
                return (lhs.extract?.count ?? 0) > (rhs.extract?.count ?? 0)
            }
    }

    private static func mapToActivity(page: PageDetail) -> CityActivity {
        let (category, kind) = Self.deriveCategory(
            from: page.extract ?? "",
            title: page.title
        )

        let imageURL: URL? = if let source = page.original?.source {
            URL(string: source)
        } else if let source = page.thumbnail?.source {
            URL(string: source)
        } else {
            nil
        }

        let coordinate = page.coordinates?.first

        let encodedTitle = page.title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? page.title

        let sourceURL = URL(
            string: "https://en.wikipedia.org/wiki/\(encodedTitle)",
            encodingInvalidCharacters: true
        )

        return CityActivity(
            id: "wiki-\(page.pageid)",
            name: page.title,
            summary: Self.cleanExtract(page.extract ?? ""),
            category: category,
            kind: kind,
            imageURL: imageURL,
            officialURL: nil,
            sourceURL: sourceURL,
            sourceName: "Wikipedia",
            hours: nil,
            price: nil,
            address: nil,
            directions: nil,
            timingTip: nil,
            latitude: coordinate?.lat,
            longitude: coordinate?.lon,
            wikidataIdentifier: page.pageprops?.wikidataItem,
            sourcePageTitle: page.title,
            sourceAnchor: nil
        )
    }

    private static func deriveCategory(
        from extract: String,
        title: String
    ) -> (String, CityActivity.Kind) {
        let text = "\(title) \(extract)".lowercased()

        for (keywords, category, kind) in Self.categoryRules {
            for keyword in keywords {
                if text.localizedStandardContains(keyword) {
                    return (category, kind)
                }
            }
        }

        return ("Attraction", .see)
    }

    private static let categoryRules: [([String], String, CityActivity.Kind)] = [
        (["museum", "gallery", "exhibit"], "Museum", .see),
        (["park", "garden", "botanical", "forest", "trail"], "Nature", .do),
        (["bridge", "tower", "monument", "statue", "memorial"], "Landmark", .see),
        (["church", "cathedral", "temple", "mosque", "basilica", "chapel"], "Architecture", .see),
        (["beach", "island", "bay", "lake", "waterfall", "reef"], "Nature", .see),
        (["theater", "theatre", "opera", "concert", "performing"], "Entertainment", .do),
        (["stadium", "arena", "ballpark"], "Sports", .do),
        (["market", "square", "plaza", "bazaar", "wharf", "pier"], "Culture", .do),
        (["palace", "castle", "fort", "fortress", "citadel"], "Heritage", .see),
        (["zoo", "aquarium", "amusement", "theme park"], "Family", .do),
        (["library", "university", "observatory", "planetarium"], "Education", .see),
        (["harbor", "harbour", "lighthouse", "dam"], "Landmark", .see)
    ]

    private static func cleanExtract(_ text: String) -> String {
        text
            .replacingOccurrences(
                of: "\\s*==.*$",
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Wikipedia API

extension CityActivityService {
    private func geoSearch(
        latitude: Double,
        longitude: Double
    ) async throws -> [GeoSearchResult] {
        var components = URLComponents(
            string: "https://en.wikipedia.org/w/api.php"
        )
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
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(
            GeoSearchResponse.self, from: data
        )
        return response.query.geosearch
    }

    private func pageDetails(
        for titles: [String]
    ) async throws -> [PageDetail] {
        guard !titles.isEmpty else { return [] }

        var components = URLComponents(
            string: "https://en.wikipedia.org/w/api.php"
        )
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
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(
            PageQueryResponse.self, from: data
        )
        return response.query.pages
    }
}

// MARK: - Wikidata Image Resolution

extension CityActivityService {
    private func resolveWikidataImages(
        for activities: [CityActivity]
    ) async -> [CityActivity] {
        let needsImage = activities.filter {
            $0.imageURL == nil && $0.wikidataIdentifier != nil
        }

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
        let batch = Array(ids.prefix(50))
        let joined = batch.joined(separator: "|")

        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )
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
            let response = try self.decoder.decode(
                WikidataEntitiesResponse.self, from: data
            )

            var map: [String: URL] = [:]

            for (qid, entity) in response.entities {
                guard let claims = entity.claims?["P18"],
                      let firstClaim = claims.first,
                      let fileName = firstClaim.mainsnak.datavalue?.value.stringValue
                else { continue }

                let encoded = fileName
                    .replacingOccurrences(of: " ", with: "_")
                    .addingPercentEncoding(
                        withAllowedCharacters: .urlPathAllowed
                    ) ?? ""

                guard !encoded.isEmpty,
                      let imageURL = URL(
                        string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)"
                      )
                else { continue }

                map[qid] = imageURL
            }

            return map
        } catch {
            self.logger.debug(
                "Wikidata image fetch failed: \(error.localizedDescription, privacy: .public)"
            )
            return [:]
        }
    }
}

// MARK: - Networking

extension CityActivityService {
    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-activities"))",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await self.session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= http.statusCode else {
            throw ServiceError.httpStatus(http.statusCode)
        }

        return data
    }
}

// MARK: - Disk Cache

extension CityActivityService {
    private func loadFromDisk(at url: URL) -> CachedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? self.decoder.decode(CachedPayload.self, from: data)
    }

    private func writeToDisk(_ payload: CachedPayload, at url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func diskCacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityActivities", directoryHint: .isDirectory)
            .appending(
                path: "\(Self.cacheKey(for: city)).json",
                directoryHint: .notDirectory
            )
    }

    private static func cacheKey(for city: CityModel) -> String {
        city.id
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")
    }
}

// MARK: - Response Models

extension CityActivityService {
    private struct CachedPayload: Codable, Sendable {
        let fetchedAt: Date
        let activities: [CityActivity]

        func isValid(lifetime: TimeInterval) -> Bool {
            self.fetchedAt.addingTimeInterval(lifetime) > .now
        }
    }

    private enum ServiceError: Error {
        case invalidResponse
        case invalidRequest
        case httpStatus(Int)
    }

    // MARK: Wikipedia

    private struct GeoSearchResponse: Decodable {
        let query: GeoSearchQuery
    }

    private struct GeoSearchQuery: Decodable {
        let geosearch: [GeoSearchResult]
    }

    private struct GeoSearchResult: Decodable, Sendable {
        let pageid: Int
        let title: String
        let lat: Double
        let lon: Double
        let dist: Double
    }

    private struct PageQueryResponse: Decodable {
        let query: PageQueryData
    }

    private struct PageQueryData: Decodable {
        let pages: [PageDetail]
    }

    private struct PageDetail: Decodable {
        let pageid: Int
        let title: String
        let extract: String?
        let thumbnail: PageImage?
        let original: PageImage?
        let coordinates: [PageCoordinate]?
        let pageprops: PageProps?
    }

    private struct PageImage: Decodable {
        let source: String
        let width: Int?
        let height: Int?
    }

    private struct PageCoordinate: Decodable {
        let lat: Double
        let lon: Double
    }

    private struct PageProps: Decodable {
        let wikibase_item: String?

        var wikidataItem: String? { self.wikibase_item }

        private enum CodingKeys: String, CodingKey {
            case wikibase_item
        }
    }

    // MARK: Wikidata

    private struct WikidataEntitiesResponse: Decodable {
        let entities: [String: WikidataEntity]
    }

    private struct WikidataEntity: Decodable {
        let claims: [String: [WikidataClaim]]?
    }

    private struct WikidataClaim: Decodable {
        let mainsnak: WikidataMainsnak
    }

    private struct WikidataMainsnak: Decodable {
        let datavalue: WikidataDatavalue?
    }

    private struct WikidataDatavalue: Decodable {
        let value: WikidataValue
    }

    private struct WikidataValue: Decodable {
        let stringValue: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.stringValue = try? container.decode(String.self)
        }
    }
}
