import CoreLocation
import Foundation

extension CityActivityRanking {
    static func selectDiverseActivities(
        from scored: [ScoredActivity],
        limit: Int
    ) -> [CityActivity] {
        var remaining = scored
        var selected: [ScoredActivity] = []
        var seenCategories: Set<String> = []
        var kindCounts: [CityActivity.Kind: Int] = [:]

        while selected.count < limit, !remaining.isEmpty {
            let bestIndex = remaining.indices.max { lhs, rhs in
                self.selectionScore(
                    for: remaining[lhs],
                    seenCategories: seenCategories,
                    kindCounts: kindCounts
                ) < self.selectionScore(
                    for: remaining[rhs],
                    seenCategories: seenCategories,
                    kindCounts: kindCounts
                )
            }

            guard let bestIndex else { break }
            let bestCandidate = remaining.remove(at: bestIndex)
            selected.append(bestCandidate)
            seenCategories.insert(bestCandidate.primaryCategoryKey)
            kindCounts[bestCandidate.activity.kind, default: 0] += 1
        }

        return selected.map(\.activity)
    }

    static func selectionScore(
        for candidate: ScoredActivity,
        seenCategories: Set<String>,
        kindCounts: [CityActivity.Kind: Int]
    ) -> Int {
        var adjustedScore = candidate.baseScore

        adjustedScore += seenCategories.contains(candidate.primaryCategoryKey) ? -1 : 2

        let currentKindCount = kindCounts[candidate.activity.kind, default: 0]
        let otherKind: CityActivity.Kind = candidate.activity.kind == .see ? .do : .see
        let otherKindCount = kindCounts[otherKind, default: 0]
        if currentKindCount <= otherKindCount {
            adjustedScore += 1
        }

        return adjustedScore
    }

    static func mergePreferenceScore(_ activity: CityActivity) -> Int {
        var score = self.sourcePreference(activity.sourceName)
        score += self.categorySpecificityScore(activity.category) * 4
        score += self.practicalInfoCount(for: activity) * 5
        score += self.metadataRichnessScore(for: activity) * 2
        score += min(activity.summary.count, 280) / 20
        return score
    }

    static func mergedActivity(
        preferred: CityActivity,
        supplemental: CityActivity
    ) -> CityActivity {
        let mergedCategory = self.preferredCategory(
            primary: preferred.category,
            secondary: supplemental.category
        )
        let mergedKind = self.preferredKind(
            primary: preferred,
            secondary: supplemental,
            mergedCategory: mergedCategory
        )

        return CityActivity(
            id: preferred.id,
            name: preferred.name,
            summary: self.preferredSummary(primary: preferred, secondary: supplemental),
            category: mergedCategory,
            kind: mergedKind,
            imageURL: preferred.imageURL ?? supplemental.imageURL,
            officialURL: preferred.officialURL ?? supplemental.officialURL,
            sourceURL: preferred.sourceURL ?? supplemental.sourceURL,
            sourceName: preferred.sourceName,
            hours: preferred.hours ?? supplemental.hours,
            price: preferred.price ?? supplemental.price,
            address: preferred.address ?? supplemental.address,
            directions: preferred.directions ?? supplemental.directions,
            timingTip: preferred.timingTip ?? supplemental.timingTip,
            latitude: preferred.latitude ?? supplemental.latitude,
            longitude: preferred.longitude ?? supplemental.longitude,
            wikidataIdentifier: preferred.wikidataIdentifier ?? supplemental.wikidataIdentifier,
            sourcePageTitle: preferred.sourcePageTitle ?? supplemental.sourcePageTitle,
            sourceAnchor: preferred.sourceAnchor ?? supplemental.sourceAnchor
        )
    }

    static func preferredSummary(
        primary: CityActivity,
        secondary: CityActivity
    ) -> String {
        if primary.sourceName == "Wikivoyage", primary.summary.count >= 90 {
            return primary.summary
        }

        if secondary.sourceName == "Wikivoyage", secondary.summary.count >= 90 {
            return secondary.summary
        }

        return primary.summary.count >= secondary.summary.count
            ? primary.summary
            : secondary.summary
    }

    static func preferredCategory(primary: String, secondary: String) -> String {
        let primaryScore = self.categorySpecificityScore(primary)
        let secondaryScore = self.categorySpecificityScore(secondary)

        if secondaryScore > primaryScore {
            return secondary
        }

        return primary
    }

    static func preferredKind(
        primary: CityActivity,
        secondary: CityActivity,
        mergedCategory: String
    ) -> CityActivity.Kind {
        switch self.normalizedCategoryKey(mergedCategory) {
        case "culture", "entertainment", "family", "nature", "sports":
            primary.kind == .do || secondary.kind == .do ? .do : primary.kind
        default:
            primary.kind
        }
    }

    static func practicalInfoCount(for activity: CityActivity) -> Int {
        let values: [String?] = [
            activity.hours,
            activity.price,
            activity.address,
            activity.directions,
            activity.timingTip
        ]

        return values.reduce(into: 0) { count, value in
            guard let value, !value.isEmpty else { return }
            count += 1
        }
    }

    static func metadataRichnessScore(for activity: CityActivity) -> Int {
        var score = 0

        if activity.imageURL != nil { score += 1 }
        if activity.officialURL != nil { score += 1 }
        if activity.sourceURL != nil { score += 1 }
        if activity.hours != nil { score += 1 }
        if activity.price != nil { score += 1 }
        if activity.address != nil { score += 1 }
        if activity.directions != nil { score += 1 }
        if activity.timingTip != nil { score += 1 }
        if activity.latitude != nil, activity.longitude != nil { score += 1 }
        if activity.wikidataIdentifier != nil { score += 1 }

        return score
    }

    static func categoryGroup(for activity: CityActivity) -> CategoryGroup {
        let categoryKey = self.normalizedCategoryKey(activity.category)
        let searchText = self.normalizedActivityName("\(activity.name) \(activity.summary)")

        if self.signatureCategoryKeys.contains(categoryKey)
            || self.signatureKeywords.contains(where: { searchText.localizedStandardContains($0) })
        {
            return .signature
        }

        if activity.kind == .do || self.experientialCategoryKeys.contains(categoryKey) {
            return .experiential
        }

        return .supporting
    }

    static func sourcePreference(_ sourceName: String) -> Int {
        switch sourceName {
        case "Wikivoyage":
            32
        case "OpenStreetMap":
            28
        case "Wikipedia":
            24
        default:
            18
        }
    }

    static func categorySpecificityScore(_ category: String) -> Int {
        switch self.normalizedCategoryKey(category) {
        case "attraction":
            0
        case "culture", "entertainment", "family", "nature", "sports":
            1
        default:
            2
        }
    }

    static func normalizedActivityName(_ name: String) -> String {
        name
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: " ")
            .lowercased()
    }

    static func normalizedCategoryKey(_ category: String) -> String {
        self.normalizedActivityName(category)
    }

    static func distance(
        from cityCoordinate: CLLocationCoordinate2D,
        latitude: Double?,
        longitude: Double?
    ) -> CLLocationDistance? {
        guard let latitude, let longitude else { return nil }

        let cityLocation = CLLocation(
            latitude: cityCoordinate.latitude,
            longitude: cityCoordinate.longitude
        )
        let activityLocation = CLLocation(latitude: latitude, longitude: longitude)
        return cityLocation.distance(from: activityLocation)
    }

    static let signatureCategoryKeys: Set<String> = [
        "architecture",
        "art",
        "gallery",
        "heritage",
        "landmark",
        "museum",
        "viewpoint",
        "zoo",
        "aquarium",
        "theme park",
        "education"
    ]

    static let experientialCategoryKeys: Set<String> = [
        "culture",
        "entertainment",
        "family",
        "nature",
        "sports"
    ]

    static let signatureKeywords = [
        "basilica",
        "castle",
        "cathedral",
        "citadel",
        "fort",
        "historic",
        "landmark",
        "museum",
        "palace",
        "tower",
        "viewpoint"
    ]
}
