// WikipediaSummaryService.swift
// Tourism Beats
//
// Fetches article summaries from the Wikipedia REST API.
// Used to enrich activity detail views with descriptions,
// images, and article links when the initial pipeline
// produced only a generic fallback summary.

import Foundation
import OSLog

// MARK: - WikipediaSummaryProviding

protocol WikipediaSummaryProviding: Sendable {
    func summary(for title: String, near cityName: String) async -> WikipediaSummary?
}

// MARK: - WikipediaSummary

struct WikipediaSummary: Sendable {
    let title: String
    let description: String?
    let extract: String
    let thumbnailURL: URL?
    let originalImageURL: URL?
    let articleURL: URL?
}

// MARK: - WikipediaSummaryService

actor WikipediaSummaryService: WikipediaSummaryProviding {
    static let shared = WikipediaSummaryService()

    private let session: URLSession
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "tourism-beats",
        category: "WikipediaSummary"
    )
    private var cache: [String: WikipediaSummary?] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func summary(for title: String, near cityName: String) async -> WikipediaSummary? {
        let key = "\(title)|\(cityName)".lowercased()

        if let cached = self.cache[key] {
            return cached
        }

        let result = await self.resolve(title: title, cityName: cityName)
        self.cache[key] = result
        return result
    }

    // MARK: - Resolution Pipeline

    /// Attempts to find a useful (non-disambiguation) Wikipedia article.
    /// Tries, in order:
    /// 1. The exact title
    /// 2. "Title (cityName)" — common Wikipedia disambiguation pattern
    /// 3. "Title, cityName" — alternate naming convention
    private func resolve(title: String, cityName: String) async -> WikipediaSummary? {
        let candidates = Self.buildCandidates(title: title, cityName: cityName)

        for candidate in candidates {
            do {
                let response = try await self.fetchSummary(for: candidate)

                // Skip disambiguation pages — they list multiple topics
                // rather than providing a useful article extract.
                guard response.type != "disambiguation" else {
                    self.logger.info("Skipping disambiguation page for '\(candidate, privacy: .public)'")
                    continue
                }

                // Skip pages with very short extracts (stubs or redirects).
                guard response.extract != nil, (response.extract?.count ?? 0) > 30 else {
                    continue
                }

                return self.mapResponse(response)
            } catch {
                self.logger.debug("No Wikipedia article for '\(candidate, privacy: .public)': \(error)")
                continue
            }
        }

        return nil
    }

    /// Builds an ordered list of Wikipedia title candidates to try.
    private static func buildCandidates(title: String, cityName: String) -> [String] {
        var candidates = [title]

        let parenthetical = "\(title) (\(cityName))"
        if parenthetical != title {
            candidates.append(parenthetical)
        }

        let comma = "\(title), \(cityName)"
        if comma != title {
            candidates.append(comma)
        }

        return candidates
    }

    // MARK: - Networking

    private func fetchSummary(for title: String) async throws -> APIResponse {
        let encoded = title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title

        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 10
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "wikipedia-summary"))",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await self.session.data(for: request)

        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(APIResponse.self, from: data)
    }

    private func mapResponse(_ response: APIResponse) -> WikipediaSummary {
        let articleURL: URL? = if let mobile = response.content_urls?.mobile?.page {
            URL(string: mobile)
        } else {
            nil
        }

        return WikipediaSummary(
            title: response.title,
            description: response.description,
            extract: response.extract ?? "",
            thumbnailURL: response.thumbnail.flatMap { URL(string: $0.source) },
            originalImageURL: response.originalimage.flatMap { URL(string: $0.source) },
            articleURL: articleURL
        )
    }
}

// MARK: - API Response Models

private extension WikipediaSummaryService {
    struct APIResponse: Decodable {
        let type: String?
        let title: String
        let description: String?
        let extract: String?
        let thumbnail: ImageRef?
        let originalimage: ImageRef?
        let content_urls: ContentURLs?
    }

    struct ImageRef: Decodable {
        let source: String
        let width: Int?
        let height: Int?
    }

    struct ContentURLs: Decodable {
        let mobile: PageURL?
    }

    struct PageURL: Decodable {
        let page: String?
    }
}
