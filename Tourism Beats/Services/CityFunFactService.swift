import Foundation
import NaturalLanguage
import OSLog

// MARK: - CityFunFactService

actor CityFunFactService: CityFunFactProviding {
    static let shared = CityFunFactService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityFunFactService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 30

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func facts(for city: CityModel) async -> [CityFunFact] {
        let cacheURL = self.cacheURL(for: city)

        if let cached = self.cachedPayload(at: cacheURL),
           cached.fetchedAt.addingTimeInterval(self.cacheLifetime) > Date.now
        {
            return cached.cityFunFacts
        }

        do {
            let fetched = try await self.fetchPayload(for: city)
            try self.store(fetched, at: cacheURL)
            return fetched.cityFunFacts
        } catch {
            self.logger.error(
                "Fact fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            if let cached = self.cachedPayload(at: cacheURL) {
                return cached.cityFunFacts
            }

            return [Self.fallbackFact(for: city)]
        }
    }

    private func fetchPayload(for city: CityModel) async throws -> CachedFactPayload {
        for title in try await self.candidateTitles(for: city) {
            do {
                let page = try await self.fetchPage(title: title)
                let facts = Self.interestingFacts(from: page.extract)

                guard !facts.isEmpty else { continue }

                return CachedFactPayload(
                    facts: facts,
                    sourceName: "Wikipedia",
                    sourceURL: Self.wikipediaURL(for: page.title),
                    fetchedAt: Date.now
                )
            } catch {
                self.logger.debug(
                    "Skipping title \(title, privacy: .public) for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        throw CityFunFactServiceError.factUnavailable
    }

    private func candidateTitles(for city: CityModel) async throws -> [String] {
        let searchURL = try self.makeSearchURL(for: city)
        let request = self.makeRequest(url: searchURL)
        let (data, response) = try await self.session.data(for: request)
        try Self.validate(response: response)

        let searchResponse = try self.decoder.decode(
            SearchResponse.self,
            from: data
        )
        let initialTitles = [
            city.name,
            "\(city.name), \(city.country.name)",
            "\(city.name) \(city.country.name)"
        ]

        return Self.uniquedTitles(
            initialTitles + searchResponse.query.search.map(\.title)
        )
    }

    private func fetchPage(title: String) async throws -> PageSummary {
        let url = try self.makeExtractURL(for: title)
        let request = self.makeRequest(url: url)
        let (data, response) = try await self.session.data(for: request)
        try Self.validate(response: response)

        let payload = try self.decoder.decode(ExtractResponse.self, from: data)
        guard
            let page = payload.query.pages.first,
            let title = page.title,
            let extract = page.extract,
            !extract.isEmpty
        else {
            throw CityFunFactServiceError.factUnavailable
        }

        return PageSummary(title: title, extract: extract)
    }

    private func makeSearchURL(for city: CityModel) throws -> URL {
        var components = URLComponents(
            string: "https://en.wikipedia.org/w/api.php"
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
            throw CityFunFactServiceError.invalidRequest
        }
        return url
    }

    private func makeExtractURL(for title: String) throws -> URL {
        var components = URLComponents(
            string: "https://en.wikipedia.org/w/api.php"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "prop", value: "extracts"),
            URLQueryItem(name: "exintro", value: "1"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "redirects", value: "1"),
            URLQueryItem(name: "titles", value: title)
        ]

        guard let url = components?.url else {
            throw CityFunFactServiceError.invalidRequest
        }
        return url
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 8
        request.setValue(
            "TourismBeats/1.0 (City facts)",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    private func cachedPayload(at url: URL) -> CachedFactPayload? {
        do {
            let data = try Data(contentsOf: url)
            return try self.decoder.decode(CachedFactPayload.self, from: data)
        } catch {
            return nil
        }
    }

    private func store(_ payload: CachedFactPayload, at url: URL) throws {
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
            .appending(path: "CityFacts", directoryHint: .isDirectory)
            .appending(
                path: "\(Self.cacheKey(for: city)).json",
                directoryHint: .notDirectory
            )
    }

    private static func cacheKey(for city: CityModel) -> String {
        let normalized = city.id.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )

        return normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")
    }

    private static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CityFunFactServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw CityFunFactServiceError.httpStatus(httpResponse.statusCode)
        }
    }

    private static func interestingFacts(from extract: String) -> [String] {
        let normalizedText = extract
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedText.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = normalizedText

        var results: [String] = []
        tokenizer.enumerateTokens(
            in: normalizedText.startIndex ..< normalizedText.endIndex
        ) { range, _ in
            let sentence = normalizedText[range]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard Self.isFactCandidate(sentence) else {
                return true
            }

            results.append(Self.clampedSentence(sentence))
            return results.count < 4
        }

        if results.isEmpty {
            results.append(Self.clampedSentence(normalizedText))
        }

        return Self.uniquedFacts(results)
    }

    private static func isFactCandidate(_ sentence: String) -> Bool {
        guard sentence.count >= 48 else { return false }
        let lowered = sentence.lowercased()

        if lowered.contains("may refer to") { return false }
        if lowered.contains("coordinates") { return false }
        if lowered.contains("listen") { return false }

        return true
    }

    private static func clampedSentence(_ sentence: String) -> String {
        guard sentence.count > 180 else { return sentence }

        let truncated = sentence.prefix(180)
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "…"
        }

        return String(truncated) + "…"
    }

    private static func wikipediaURL(for title: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "en.wikipedia.org"
        components.path = "/wiki/\(title.split(separator: " ").joined(separator: "_"))"
        return components.url
    }

    private static func fallbackFact(for city: CityModel) -> CityFunFact {
        let timeZoneName = city.timeZone.localizedName(
            for: .generic,
            locale: .current
        ) ?? city.timeZoneIdentifier

        return CityFunFact(
            text: "\(city.name) follows \(timeZoneName), which helps anchor trip planning across \(city.country.name) when you line up flights, meals, and music picks.",
            sourceName: "Local metadata",
            sourceURL: nil,
            isFallback: true
        )
    }

    private static func uniquedTitles(_ titles: [String]) -> [String] {
        var seen = Set<String>()

        return titles.compactMap { title in
            let normalized = title
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return nil }
            guard seen.insert(normalized.lowercased()).inserted else {
                return nil
            }
            return normalized
        }
    }

    private static func uniquedFacts(_ facts: [String]) -> [String] {
        var seen = Set<String>()

        return facts.compactMap { fact in
            guard seen.insert(fact.lowercased()).inserted else {
                return nil
            }
            return fact
        }
    }
}

private extension CityFunFactService {
    struct CachedFactPayload: Codable, Sendable {
        let facts: [String]
        let sourceName: String
        let sourceURL: URL?
        let fetchedAt: Date

        var cityFunFacts: [CityFunFact] {
            self.facts.map {
                CityFunFact(
                    text: $0,
                    sourceName: self.sourceName,
                    sourceURL: self.sourceURL,
                    isFallback: false
                )
            }
        }
    }

    struct SearchResponse: Decodable, Sendable {
        let query: SearchQuery
    }

    struct SearchQuery: Decodable, Sendable {
        let search: [SearchResult]
    }

    struct SearchResult: Decodable, Sendable {
        let title: String
    }

    struct ExtractResponse: Decodable, Sendable {
        let query: ExtractQuery
    }

    struct ExtractQuery: Decodable, Sendable {
        let pages: [ExtractPage]
    }

    struct ExtractPage: Decodable, Sendable {
        let title: String?
        let extract: String?
    }

    struct PageSummary: Sendable {
        let title: String
        let extract: String
    }

    enum CityFunFactServiceError: LocalizedError {
        case invalidRequest
        case invalidResponse
        case httpStatus(Int)
        case factUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidRequest:
                "Could not build the city fact request."
            case .invalidResponse:
                "The fact source returned an invalid response."
            case let .httpStatus(code):
                "The fact source returned status code \(code)."
            case .factUnavailable:
                "No city fact is available right now."
            }
        }
    }
}
