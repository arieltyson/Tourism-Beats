import Foundation

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
