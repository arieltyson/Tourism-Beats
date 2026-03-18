import Foundation
import OSLog

// MARK: - CityActivityService

actor CityActivityService: CityActivityProviding {
    static let shared = CityActivityService()

    private let session: URLSession
    private let parser: WikivoyageActivityParser
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityActivityService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 14

    private var payloadCache: [String: CachedActivityPayload] = [:]
    private var pageWikitextCache: [String: String] = [:]

    init(
        session: URLSession = .shared,
        parser: WikivoyageActivityParser = WikivoyageActivityParser()
    ) {
        self.session = session
        self.parser = parser

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func activities(for city: CityModel) async -> [CityActivity] {
        let cacheKey = Self.cacheKey(for: city)

        if let cachedPayload = self.payloadCache[cacheKey],
           cachedPayload.fetchedAt.addingTimeInterval(self.cacheLifetime) > Date.now
        {
            return cachedPayload.activities
        }

        let cacheURL = self.cacheURL(for: city)

        if let cachedPayload = self.cachedPayload(at: cacheURL),
           cachedPayload.fetchedAt.addingTimeInterval(self.cacheLifetime) > Date.now
        {
            self.payloadCache[cacheKey] = cachedPayload
            return cachedPayload.activities
        }

        do {
            let fetchedPayload = try await self.fetchPayload(for: city)
            try self.store(fetchedPayload, at: cacheURL)
            self.payloadCache[cacheKey] = fetchedPayload
            return fetchedPayload.activities
        } catch {
            self.logger.error(
                "Activity fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            if let stalePayload = self.cachedPayload(at: cacheURL) {
                self.payloadCache[cacheKey] = stalePayload
                return stalePayload.activities
            }

            return []
        }
    }
}

extension CityActivityService {
    private struct CachedActivityPayload: Codable, Sendable {
        let fetchedAt: Date
        let activities: [CityActivity]
    }

    private struct ResolvedGuidePage: Sendable {
        let title: String
        let seeSectionIndex: String?
        let doSectionIndex: String?
    }

    private struct SearchResponse: Decodable {
        let query: SearchQuery
    }

    private struct SearchQuery: Decodable {
        let search: [SearchResult]
    }

    private struct SearchResult: Decodable {
        let title: String
    }

    private struct WikitextResponse: Decodable {
        let parse: ParsedWikitext
    }

    private struct ParsedWikitext: Decodable {
        let wikitext: String
    }

    private struct TocDataResponse: Decodable {
        let parse: ParsedTocData
    }

    private struct ParsedTocData: Decodable {
        let tocdata: TocData
    }

    private struct TocData: Decodable {
        let sections: [SectionReference]
    }

    private struct SectionReference: Decodable {
        let line: String
        let index: String
    }

    private enum ServiceError: Error {
        case invalidResponse
        case invalidRequest
        case httpStatus(Int)
        case guideUnavailable
    }

    private func fetchPayload(for city: CityModel) async throws -> CachedActivityPayload {
        let guidePage = try await self.resolveGuidePage(for: city)
        let primaryActivities = try await self.primaryActivities(
            for: guidePage,
            city: city
        )
        let topActivities = Array(primaryActivities.prefix(6))
        let enrichedActivities = try await self.enrichedActivities(
            topActivities,
            guidePageTitle: guidePage.title
        )
        let imageResolvedActivities = await self.activitiesWithWikidataImages(
            enrichedActivities
        )

        return CachedActivityPayload(
            fetchedAt: Date.now,
            activities: imageResolvedActivities
        )
    }

    private func resolveGuidePage(for city: CityModel) async throws -> ResolvedGuidePage {
        let candidateTitles = try await Self.uniquedTitles(
            [
                city.name,
                "\(city.name) (\(city.country.name))",
                "\(city.name), \(city.country.name)"
            ] + (self.searchTitles(for: city))
        )

        for title in candidateTitles {
            guard !title.contains("/") else { continue }

            do {
                let guidePage = try await self.guidePage(title: title)
                if guidePage.seeSectionIndex != nil || guidePage.doSectionIndex != nil {
                    return guidePage
                }
            } catch {
                continue
            }
        }

        throw ServiceError.guideUnavailable
    }

    private func searchTitles(for city: CityModel) async throws -> [String] {
        var components = URLComponents(
            string: "https://en.wikivoyage.org/w/api.php"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srlimit", value: "5"),
            URLQueryItem(
                name: "srsearch",
                value: "\"\(city.name)\" \"\(city.country.name)\""
            )
        ]

        guard let url = components?.url else {
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(SearchResponse.self, from: data)
        return response.query.search.map(\.title)
    }

    private func guidePage(title: String) async throws -> ResolvedGuidePage {
        var components = URLComponents(
            string: "https://en.wikivoyage.org/w/api.php"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: title),
            URLQueryItem(name: "prop", value: "tocdata"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(TocDataResponse.self, from: data)
        let seeSectionIndex = response.parse.tocdata.sections
            .first(where: { $0.line.caseInsensitiveCompare("See") == .orderedSame })?
            .index
        let doSectionIndex = response.parse.tocdata.sections
            .first(where: { $0.line.caseInsensitiveCompare("Do") == .orderedSame })?
            .index

        return ResolvedGuidePage(
            title: title,
            seeSectionIndex: seeSectionIndex,
            doSectionIndex: doSectionIndex
        )
    }

    private func primaryActivities(
        for guidePage: ResolvedGuidePage,
        city: CityModel
    ) async throws -> [CityActivity] {
        var activities: [CityActivity] = []

        if let seeSectionIndex = guidePage.seeSectionIndex {
            let seeWikitext = try await self.sectionWikitext(
                pageTitle: guidePage.title,
                sectionIndex: seeSectionIndex
            )
            activities.append(
                contentsOf: self.parser.activities(
                    from: seeWikitext,
                    defaultKind: .see,
                    sourcePageTitle: guidePage.title
                )
            )
        }

        if let doSectionIndex = guidePage.doSectionIndex {
            let doWikitext = try await self.sectionWikitext(
                pageTitle: guidePage.title,
                sectionIndex: doSectionIndex
            )
            activities.append(
                contentsOf: self.parser.activities(
                    from: doWikitext,
                    defaultKind: .do,
                    sourcePageTitle: guidePage.title
                )
            )
        }

        if activities.isEmpty {
            self.logger.notice(
                "No activity listings found for \(city.id, privacy: .public) using guide page \(guidePage.title, privacy: .public)"
            )
        }

        return activities
    }

    private func enrichedActivities(
        _ activities: [CityActivity],
        guidePageTitle: String
    ) async throws -> [CityActivity] {
        var enrichedActivities: [CityActivity] = []

        for activity in activities {
            do {
                let enrichedActivity = try await self.enrichedActivity(
                    activity,
                    guidePageTitle: guidePageTitle
                )
                enrichedActivities.append(enrichedActivity)
            } catch {
                self.logger.debug(
                    "Detail enrichment failed for \(activity.name, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
                enrichedActivities.append(activity)
            }
        }

        return enrichedActivities
    }

    private func enrichedActivity(
        _ activity: CityActivity,
        guidePageTitle: String
    ) async throws -> CityActivity {
        guard let detailPageTitle = activity.sourcePageTitle,
              !detailPageTitle.isEmpty,
              detailPageTitle.caseInsensitiveCompare(guidePageTitle) != .orderedSame
        else {
            return activity
        }

        let detailWikitext = try await self.pageWikitext(for: detailPageTitle)
        let detailCandidates = self.parser.activities(
            from: detailWikitext,
            defaultKind: activity.kind,
            sourcePageTitle: detailPageTitle
        )

        guard let detailMatch = self.match(activity, in: detailCandidates) else {
            return activity
        }

        return Self.merged(base: activity, detail: detailMatch)
    }

    private func match(
        _ activity: CityActivity,
        in candidates: [CityActivity]
    ) -> CityActivity? {
        if let wikidataIdentifier = activity.wikidataIdentifier,
           let exactMatch = candidates.first(where: {
            $0.wikidataIdentifier == wikidataIdentifier
           })
        {
            return exactMatch
        }

        if let sourceAnchor = activity.sourceAnchor,
           let exactMatch = candidates.first(where: {
            $0.wikidataIdentifier == sourceAnchor || $0.sourceAnchor == sourceAnchor
           })
        {
            return exactMatch
        }

        let normalizedName = Self.normalizedLookupValue(activity.name)

        return candidates.first(where: {
            Self.normalizedLookupValue($0.name) == normalizedName
        })
    }

    private func pageWikitext(for pageTitle: String) async throws -> String {
        if let cached = self.pageWikitextCache[pageTitle] {
            return cached
        }

        var components = URLComponents(
            string: "https://en.wikivoyage.org/w/api.php"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: pageTitle),
            URLQueryItem(name: "prop", value: "wikitext"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(WikitextResponse.self, from: data)
        self.pageWikitextCache[pageTitle] = response.parse.wikitext
        return response.parse.wikitext
    }

    private func sectionWikitext(
        pageTitle: String,
        sectionIndex: String
    ) async throws -> String {
        var components = URLComponents(
            string: "https://en.wikivoyage.org/w/api.php"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: pageTitle),
            URLQueryItem(name: "prop", value: "wikitext"),
            URLQueryItem(name: "section", value: sectionIndex),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else {
            throw ServiceError.invalidRequest
        }

        let data = try await self.fetchData(from: url)
        let response = try self.decoder.decode(WikitextResponse.self, from: data)
        return response.parse.wikitext
    }

    private func fetchData(from url: URL) async throws -> Data {
        let request = self.makeRequest(url: url)
        let (data, response) = try await self.session.data(for: request)
        try Self.validate(response: response)
        return data
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 10
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-activities"))",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    private func cachedPayload(at url: URL) -> CachedActivityPayload? {
        do {
            let data = try Data(contentsOf: url)
            return try self.decoder.decode(CachedActivityPayload.self, from: data)
        } catch {
            return nil
        }
    }

    private func store(_ payload: CachedActivityPayload, at url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func cacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityActivities", directoryHint: .isDirectory)
            .appending(
                path: "\(Self.cacheKey(for: city)).json",
                directoryHint: .notDirectory
            )
    }

    private static func cacheKey(for city: CityModel) -> String {
        self.normalizedLookupValue(city.id)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")
    }

    private static func normalizedLookupValue(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
    }

    private static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ServiceError.httpStatus(httpResponse.statusCode)
        }
    }

    private static func merged(base: CityActivity, detail: CityActivity) -> CityActivity {
        CityActivity(
            id: base.id,
            name: detail.name.count > base.name.count ? detail.name : base.name,
            summary: detail.summary.count > base.summary.count ? detail.summary : base.summary,
            category: base.category,
            kind: base.kind,
            imageURL: detail.imageURL ?? base.imageURL,
            officialURL: detail.officialURL ?? base.officialURL,
            sourceURL: base.sourceURL ?? detail.sourceURL,
            sourceName: base.sourceName,
            hours: detail.hours ?? base.hours,
            price: detail.price ?? base.price,
            address: detail.address ?? base.address,
            directions: detail.directions ?? base.directions,
            timingTip: detail.timingTip ?? base.timingTip,
            latitude: detail.latitude ?? base.latitude,
            longitude: detail.longitude ?? base.longitude,
            wikidataIdentifier: base.wikidataIdentifier ?? detail.wikidataIdentifier,
            sourcePageTitle: base.sourcePageTitle ?? detail.sourcePageTitle,
            sourceAnchor: base.sourceAnchor ?? detail.sourceAnchor
        )
    }

    // MARK: - Wikidata Image Resolution

    /// Resolves missing images by querying the Wikidata API (P18 property)
    /// for any activity that has a `wikidataIdentifier` but no `imageURL`.
    private func activitiesWithWikidataImages(
        _ activities: [CityActivity]
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

    /// Batch-fetches P18 (image) claims from Wikidata for up to 50 entity IDs.
    private func wikidataImageMap(for ids: [String]) async -> [String: URL] {
        let batch = Array(ids.prefix(50))
        let joined = batch.joined(separator: "|")

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
            let response = try self.decoder.decode(WikidataEntitiesResponse.self, from: data)

            var map: [String: URL] = [:]
            for (qid, entity) in response.entities {
                guard let claims = entity.claims?["P18"],
                      let firstClaim = claims.first,
                      let fileName = firstClaim.mainsnak.datavalue?.value.stringValue
                else { continue }

                let encoded = fileName
                    .replacingOccurrences(of: " ", with: "_")
                    .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

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

    // MARK: - Wikidata Response Models

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

    private static func uniquedTitles(_ titles: [String]) -> [String] {
        var seen: Set<String> = []
        var uniqueTitles: [String] = []

        for title in titles {
            let normalizedTitle = self.normalizedLookupValue(title)
            guard !normalizedTitle.isEmpty, seen.insert(normalizedTitle).inserted else {
                continue
            }
            uniqueTitles.append(title)
        }

        return uniqueTitles
    }
}
