import Foundation

// MARK: - Final Activity Summary Enrichment

extension CityActivityService {
    func enrichFallbackActivitiesIfNeeded(
        _ activities: [CityActivity],
        for city: CityModel
    ) async -> [CityActivity] {
        let lookupTitlesByIndex: [Int: String] = Dictionary(
            uniqueKeysWithValues: activities.enumerated().compactMap { index, activity in
                guard activity.hasGenericFallbackSummary,
                      let title = Self.wikipediaLookupTitle(for: activity)
                else {
                    return nil
                }

                return (index, title)
            }
        )
        guard !lookupTitlesByIndex.isEmpty else { return activities }

        let distinctTitles = Array(Set(lookupTitlesByIndex.values)).sorted()
        let cityName = city.name
        let summaryService = self.wikipediaSummaryService
        var summariesByTitle: [String: WikipediaSummary] = [:]

        await withTaskGroup(of: (String, WikipediaSummary?).self) { group in
            for title in distinctTitles {
                group.addTask {
                    let summary = await summaryService.summary(for: title, near: cityName)
                    return (title, summary)
                }
            }

            for await (title, summary) in group {
                if let summary {
                    summariesByTitle[title] = summary
                }
            }
        }

        guard !summariesByTitle.isEmpty else { return activities }

        return activities.enumerated().map { index, activity in
            guard let lookupTitle = lookupTitlesByIndex[index],
                  let summary = summariesByTitle[lookupTitle]
            else {
                return activity
            }

            return Self.activity(activity, applying: summary)
        }
    }

    private static func wikipediaLookupTitle(for activity: CityActivity) -> String? {
        if let sourcePageTitle = activity.sourcePageTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !sourcePageTitle.isEmpty
        {
            return sourcePageTitle
        }

        let trimmedName = activity.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private static func activity(
        _ activity: CityActivity,
        applying summary: WikipediaSummary
    ) -> CityActivity {
        let cleanedSummary = Self.cleanExtract(summary.extract)
        let resolvedImageURL = activity.imageURL ?? summary.originalImageURL ?? summary.thumbnailURL
        let resolvedSourceURL = activity.sourceURL ?? summary.articleURL
        let resolvedPageTitle = if let sourcePageTitle = activity.sourcePageTitle,
                                   !sourcePageTitle.isEmpty
        {
            sourcePageTitle
        } else {
            summary.title
        }

        return CityActivity(
            id: activity.id,
            name: activity.name,
            summary: cleanedSummary.isEmpty ? activity.summary : cleanedSummary,
            category: activity.category,
            kind: activity.kind,
            imageURL: resolvedImageURL,
            officialURL: activity.officialURL,
            sourceURL: resolvedSourceURL,
            sourceName: activity.sourceName,
            hours: activity.hours,
            price: activity.price,
            address: activity.address,
            directions: activity.directions,
            timingTip: activity.timingTip,
            latitude: activity.latitude,
            longitude: activity.longitude,
            wikidataIdentifier: activity.wikidataIdentifier,
            sourcePageTitle: resolvedPageTitle,
            sourceAnchor: activity.sourceAnchor
        )
    }
}
