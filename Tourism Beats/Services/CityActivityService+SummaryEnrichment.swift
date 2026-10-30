import Foundation

// MARK: - Final Activity Summary Enrichment

extension CityActivityService {
    func enrichFallbackActivitiesIfNeeded(
        _ activities: [CityActivity],
        for city: CityModel
    ) async -> [CityActivity] {
        let lookupTitlesByIndex: [Int: String] = Dictionary(
            uniqueKeysWithValues: activities.enumerated().compactMap { index, activity in
                guard activity.hasGenericFallbackSummary || activity.imageURL == nil,
                      let title = Self.wikipediaLookupTitle(for: activity)
                else {
                    return nil
                }

                return (index, title)
            }
        )
        guard !lookupTitlesByIndex.isEmpty else { return activities }

        let summaryService = self.wikipediaSummaryService
        var summariesByIndex: [Int: WikipediaSummary] = [:]

        // Each lookup carries the activity's own location, so two activities
        // sharing a title are each checked against where they actually are.
        await withTaskGroup(of: (Int, WikipediaSummary?).self) { group in
            for (index, title) in lookupTitlesByIndex {
                let context = WikipediaLookupContext(city: city, activity: activities[index])
                group.addTask {
                    let summary = await summaryService.summary(for: title, near: context)
                    return (index, summary)
                }
            }

            for await (index, summary) in group {
                if let summary {
                    summariesByIndex[index] = summary
                }
            }
        }

        guard !summariesByIndex.isEmpty else { return activities }

        return activities.enumerated().map { index, activity in
            guard let summary = summariesByIndex[index] else {
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
        let resolvedSummary = if activity.hasGenericFallbackSummary, !cleanedSummary.isEmpty {
            cleanedSummary
        } else {
            activity.summary
        }
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
            summary: resolvedSummary,
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
