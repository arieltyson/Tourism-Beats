import Foundation
import MapKit

// MARK: - Activity Demand Signals

extension CityActivityService {
    func demandSignals(
        for activities: [CityActivity],
        mapKitResults: [Models.MapKitActivityResult]
    ) async -> [String: CityActivityRanking.ActivityDemandSignal] {
        var signals = Self.mapKitDemandSignals(
            for: activities,
            mapKitResults: mapKitResults
        )

        let pageviewCounts = await self.wikipediaPageviewCounts(for: activities)
        let rankedPageviews = pageviewCounts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }

                return lhs.key < rhs.key
            }

        for (index, entry) in rankedPageviews.enumerated() {
            var signal = signals[entry.key] ?? CityActivityRanking.ActivityDemandSignal()
            signal.pageviewCount = entry.value
            signal.pageviewRank = index + 1
            signals[entry.key] = signal
        }

        return signals
    }

    func wikipediaPageviewCounts(
        for activities: [CityActivity]
    ) async -> [String: Int] {
        let titlesByActivityKey = Self.wikipediaTitlesByActivityKey(for: activities)
        let distinctTitles = Array(
            Set(titlesByActivityKey.values.flatMap(\.self))
        ).sorted()
        guard !distinctTitles.isEmpty else { return [:] }

        var countsByTitle: [String: Int] = [:]

        await withTaskGroup(of: (String, Int?).self) { group in
            for title in distinctTitles {
                group.addTask { [session = self.session] in
                    let views = await Self.fetchWikipediaPageviews(
                        for: title,
                        session: session
                    )
                    return (title, views)
                }
            }

            for await (title, views) in group {
                if let views {
                    countsByTitle[title] = views
                }
            }
        }

        var countsByActivityKey: [String: Int] = [:]
        for (activityKey, titles) in titlesByActivityKey {
            let bestCount = titles.compactMap { countsByTitle[$0] }.max()
            if let bestCount {
                countsByActivityKey[activityKey] = bestCount
            }
        }

        return countsByActivityKey
    }

    static func fetchWikipediaPageviews(
        for title: String,
        session: URLSession
    ) async -> Int? {
        let endDate = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: -1,
            to: .now
        ) ?? .now
        let startDate = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: -90,
            to: endDate
        ) ?? endDate

        let encodedTitle = title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(
                withAllowedCharacters: self.wikipediaArticlePathAllowedCharacters
            ) ?? title

        guard !encodedTitle.isEmpty else { return nil }

        let start = self.pageviewDateString(from: startDate)
        let end = self.pageviewDateString(from: endDate)
        guard !start.isEmpty, !end.isEmpty else { return nil }

        guard let url = URL(
            string: """
            https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia.org/all-access/user/\(
                encodedTitle
            )/daily/\(start)/\(end)
            """
        ) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            var request = URLRequest(url: url)
            request.cachePolicy = .useProtocolCachePolicy
            request.timeoutInterval = 15
            request.setValue(
                "TourismBeats/1.0 (activity-demand)",
                forHTTPHeaderField: "User-Agent"
            )

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  200 ..< 300 ~= http.statusCode
            else {
                return nil
            }

            let payload = try decoder.decode(Models.WikimediaPageviewsResponse.self, from: data)
            return payload.items?.reduce(into: 0) { total, item in
                total += item.views ?? 0
            }
        } catch {
            return nil
        }
    }

    static func pageviewDateString(from date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return ""
        }

        let monthText = month < 10 ? "0\(month)" : "\(month)"
        let dayText = day < 10 ? "0\(day)" : "\(day)"
        return "\(year)\(monthText)\(dayText)"
    }

    static func wikipediaTitlesByActivityKey(
        for activities: [CityActivity]
    ) -> [String: Set<String>] {
        var titlesByKey: [String: Set<String>] = [:]

        for activity in activities {
            let key = CityActivityRanking.activityKey(for: activity.name)
            let titles = self.wikipediaTitleCandidates(for: activity)
            guard !titles.isEmpty else { continue }
            titlesByKey[key, default: []].formUnion(titles)
        }

        return titlesByKey
    }

    static func wikipediaTitleCandidates(for activity: CityActivity) -> Set<String> {
        var titles: Set<String> = []

        if let sourcePageTitle = activity.sourcePageTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !sourcePageTitle.isEmpty
        {
            titles.insert(self.canonicalWikipediaTitle(sourcePageTitle))
        }

        if let sourceURL = activity.sourceURL,
           sourceURL.host?.localizedStandardContains("wikipedia.org") == true
        {
            let title = sourceURL.deletingPathExtension().lastPathComponent
            if !title.isEmpty {
                titles.insert(self.canonicalWikipediaTitle(title))
            }
        }

        if titles.isEmpty {
            titles.insert(self.canonicalWikipediaTitle(activity.name))
        }

        return Set(titles.filter { !$0.isEmpty })
    }

    static func canonicalWikipediaTitle(_ value: String) -> String {
        value.removingPercentEncoding ?? value
    }
}

extension CityActivityService {
    /// Apple Maps does not expose public star ratings through the free SDK, so
    /// the strongest free market signal we can use is repeated placement across
    /// high-intent discovery queries such as "top rated" and "best things to do."
    @MainActor
    static func multiQueryMapKitSearch(
        for city: CityModel
    ) async -> [Models.MapKitActivityResult] {
        let popularityQueries = [
            "tourist attractions",
            "popular attractions",
            "top attractions",
            "things to do"
        ]

        let reviewIntentQueries = [
            "best things to do",
            "top rated attractions",
            "must see attractions"
        ]

        var appearanceCounts: [String: Int] = [:]
        var reviewQueryCounts: [String: Int] = [:]
        var bestResultByKey: [String: Models.MapKitActivityResult] = [:]

        for query in popularityQueries {
            await self.accumulateMapKitResults(
                from: self.singleMapKitSearch(for: city, query: query),
                into: &bestResultByKey,
                appearanceCounts: &appearanceCounts,
                reviewQueryCounts: &reviewQueryCounts,
                countAsReviewIntent: false
            )
        }

        for query in reviewIntentQueries {
            await self.accumulateMapKitResults(
                from: self.singleMapKitSearch(for: city, query: query),
                into: &bestResultByKey,
                appearanceCounts: &appearanceCounts,
                reviewQueryCounts: &reviewQueryCounts,
                countAsReviewIntent: true
            )
        }

        return bestResultByKey.values.map { result in
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )

            return Models.MapKitActivityResult(
                name: result.name,
                websiteURL: result.websiteURL,
                address: result.address,
                latitude: result.latitude,
                longitude: result.longitude,
                regionName: result.regionName,
                popularityRank: result.popularityRank,
                crossQueryAppearanceCount: appearanceCounts[key, default: 1],
                reviewQueryAppearanceCount: reviewQueryCounts[key, default: 0]
            )
        }
        .sorted { lhs, rhs in
            if lhs.popularityRank != rhs.popularityRank {
                return lhs.popularityRank < rhs.popularityRank
            }

            return lhs.name < rhs.name
        }
    }

    @MainActor
    static func accumulateMapKitResults(
        from results: [Models.MapKitActivityResult],
        into bestResultByKey: inout [String: Models.MapKitActivityResult],
        appearanceCounts: inout [String: Int],
        reviewQueryCounts: inout [String: Int],
        countAsReviewIntent: Bool
    ) {
        for result in results {
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )

            appearanceCounts[key, default: 0] += 1
            if countAsReviewIntent {
                reviewQueryCounts[key, default: 0] += 1
            }

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
    static func singleMapKitSearch(
        for city: CityModel,
        query: String
    ) async -> [Models.MapKitActivityResult] {
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: city.coordinate,
                latitudinalMeters: 14_000,
                longitudinalMeters: 14_000
            )
            request.resultTypes = .pointOfInterest

            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.enumerated().compactMap { index, item in
                guard let name = item.name, !name.isEmpty else { return nil }

                let normalizedName = CityActivityRanking.activityKey(for: name)
                let cityName = CityActivityRanking.activityKey(for: city.name)

                guard normalizedName != cityName,
                      !self.activityDemandExcludedKeywords.contains(where: {
                        normalizedName.localizedStandardContains($0)
                      })
                else {
                    return nil
                }

                let coordinate = item.location.coordinate
                let result = Models.MapKitActivityResult(
                    name: name,
                    websiteURL: item.url,
                    address: self.cleanedMapKitAddress(
                        item.address?.shortAddress ?? item.address?.fullAddress
                    ),
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    regionName: item.addressRepresentations?.regionName,
                    popularityRank: index + 1
                )

                guard self.isEligibleMapKitResult(result, for: city) else {
                    return nil
                }

                return result
            }
        } catch {
            return []
        }
    }

    static func mapKitActivities(
        for city: CityModel,
        results: [Models.MapKitActivityResult],
        existingActivities: [CityActivity]
    ) -> [CityActivity] {
        let existingKeys = Set(existingActivities.map {
            CityActivityRanking.activityKey(for: $0.name)
        })

        return results.compactMap { result in
            guard self.isEligibleMapKitResult(result, for: city) else { return nil }

            let activityKey = CityActivityRanking.activityKey(for: result.name)
            guard !existingKeys.contains(activityKey) else { return nil }

            let categoryResult = Models.categoryFromText(
                title: result.name,
                extract: "Popular attraction in \(city.name)."
            )
            let coordinateKey = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )
            let summary = self.mapKitSummary(
                for: result,
                city: city,
                categoryResult: categoryResult
            )

            return CityActivity(
                id: "apple-maps-\(coordinateKey)",
                name: result.name,
                summary: summary,
                category: categoryResult.category,
                kind: categoryResult.kind,
                imageURL: nil,
                officialURL: result.websiteURL,
                sourceURL: nil,
                sourceName: "Apple Maps",
                hours: nil,
                price: nil,
                address: result.address,
                directions: nil,
                timingTip: nil,
                latitude: result.latitude,
                longitude: result.longitude,
                wikidataIdentifier: nil,
                sourcePageTitle: nil,
                sourceAnchor: nil
            )
        }
    }

    static func mapKitDemandSignals(
        for activities: [CityActivity],
        mapKitResults: [Models.MapKitActivityResult]
    ) -> [String: CityActivityRanking.ActivityDemandSignal] {
        var signals: [String: CityActivityRanking.ActivityDemandSignal] = [:]

        for activity in activities {
            let activityKey = CityActivityRanking.activityKey(for: activity.name)
            let matchingResults = mapKitResults.filter {
                self.mapKitResult($0, matches: activity)
            }
            guard !matchingResults.isEmpty else { continue }

            var signal = signals[activityKey] ?? CityActivityRanking.ActivityDemandSignal()
            signal.popularityRank = min(
                signal.popularityRank ?? .max,
                matchingResults.map(\.popularityRank).min() ?? .max
            )
            signal.crossQueryAppearanceCount = max(
                signal.crossQueryAppearanceCount,
                matchingResults.map(\.crossQueryAppearanceCount).max() ?? 0
            )
            signal.reviewQueryAppearanceCount = max(
                signal.reviewQueryAppearanceCount,
                matchingResults.map(\.reviewQueryAppearanceCount).max() ?? 0
            )
            signals[activityKey] = signal
        }

        return signals
    }

    static func mapKitResult(
        _ result: Models.MapKitActivityResult,
        matches activity: CityActivity
    ) -> Bool {
        let activityKey = CityActivityRanking.activityKey(for: activity.name)
        let resultKey = CityActivityRanking.activityKey(for: result.name)

        let nameMatches = activityKey == resultKey
            || activityKey.localizedStandardContains(resultKey)
            || resultKey.localizedStandardContains(activityKey)
        guard nameMatches else { return false }

        guard let latitude = activity.latitude, let longitude = activity.longitude else {
            return true
        }

        let activityLocation = CLLocation(latitude: latitude, longitude: longitude)
        let resultLocation = CLLocation(
            latitude: result.latitude,
            longitude: result.longitude
        )
        return activityLocation.distance(from: resultLocation) < 1_200
    }

    static func coordinateKey(latitude: Double, longitude: Double) -> String {
        "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))"
    }

    static func isEligibleMapKitResult(
        _ result: Models.MapKitActivityResult,
        for city: CityModel
    ) -> Bool {
        if let regionName = result.regionName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !regionName.isEmpty
        {
            let normalizedRegionName = CityActivityRanking.activityKey(for: regionName)
            let normalizedCountryName = CityActivityRanking.activityKey(for: city.country.name)
            let regionMatchesCountry = normalizedRegionName == normalizedCountryName
                || normalizedRegionName.localizedStandardContains(normalizedCountryName)
                || normalizedCountryName.localizedStandardContains(normalizedRegionName)

            if !regionMatchesCountry {
                return false
            }
        }

        guard let distanceFromCenter = CityActivityRanking.distance(
            from: city.coordinate,
            latitude: result.latitude,
            longitude: result.longitude
        ) else {
            return false
        }

        return distanceFromCenter <= self.maximumMapKitDistanceFromCityCenter
    }

    static let wikipediaArticlePathAllowedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return allowed
    }()

    static let maximumMapKitDistanceFromCityCenter: CLLocationDistance = 35_000

    static let activityDemandExcludedKeywords = excludedKeywords + [
        "airport",
        "bar",
        "cafe",
        "campground",
        "hotel",
        "mall",
        "restaurant",
        "station"
    ]
}
