import Foundation
import OSLog

// MARK: - Wikipedia GeoSearch Fallback

extension CityActivityService {
    func wikiGeoSearch(
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

    func wikiPageDetails(
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

    static func filterGeoResults(
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

    static func rankPages(_ pages: [Models.WikiPageDetail]) -> [Models.WikiPageDetail] {
        pages
            .filter { ($0.extract?.count ?? 0) >= 80 }
            .sorted { lhs, rhs in
                let lhsImage = lhs.thumbnail != nil || lhs.original != nil
                let rhsImage = rhs.thumbnail != nil || rhs.original != nil
                if lhsImage != rhsImage { return lhsImage }
                return (lhs.extract?.count ?? 0) > (rhs.extract?.count ?? 0)
            }
    }

    static func mapPageToActivity(page: Models.WikiPageDetail) -> CityActivity {
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

    static func cleanExtract(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s*==.*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
