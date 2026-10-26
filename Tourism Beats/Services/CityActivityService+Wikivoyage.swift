import Foundation
import OSLog

// MARK: - Wikivoyage Guide Fallback

extension CityActivityService {
    func wikivoyageActivities(for city: CityModel) async -> [CityActivity] {
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

    func wikivoyageGuidePageTitle(for city: CityModel) async throws -> String? {
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

    func wikivoyageGeoSearch(
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

    func wikivoyageTOCSections(
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

    func wikivoyageSectionWikitext(
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

    static func bestWikivoyageGuideTitle(
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

    static func guideTitleScore(_ title: String, cityName: String) -> Int {
        let normalizedTitle = Self.normalizedGuideTitle(title)
        var score = 0

        if normalizedTitle == cityName { score += 100 }
        if normalizedTitle.hasPrefix("\(cityName) ") { score += 40 }
        if !title.contains("/") { score += 25 }
        if normalizedTitle.localizedStandardContains(cityName) { score += 20 }
        if title.contains("/") { score -= 20 }

        return score
    }

    static func normalizedGuideTitle(_ value: String) -> String {
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

    static func wikivoyageActivitySections(
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
