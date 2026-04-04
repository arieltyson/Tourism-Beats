import CoreLocation
import Foundation

// MARK: - CityActivityRanking

enum CityActivityRanking {
    struct ScoredActivity: Sendable {
        let activity: CityActivity
        let baseScore: Int
        let topSignals: [Signal]
        let distanceFromCenter: CLLocationDistance?
        let primaryCategoryKey: String
    }

    enum Signal: Sendable {
        case editorialGuide
        case crossSourceConfirmed
        case practicalInfoRich
        case signatureAttraction
        case experientialPick
        case visualReference
        case locationPinned
        case centralLocation

        var points: Int {
            switch self {
            case .editorialGuide:
                12
            case .crossSourceConfirmed:
                14
            case .practicalInfoRich:
                8
            case .signatureAttraction:
                10
            case .experientialPick:
                7
            case .visualReference:
                5
            case .locationPinned:
                4
            case .centralLocation:
                3
            }
        }
    }

    static func topActivities(
        from activities: [CityActivity],
        for city: CityModel,
        limit: Int = 6
    ) -> [CityActivity] {
        let scored = self
            .consolidatedActivities(from: activities)
            .map { self.score($0, cityCoordinate: city.coordinate) }
            .sorted { lhs, rhs in
                if lhs.baseScore != rhs.baseScore {
                    return lhs.baseScore > rhs.baseScore
                }

                return (lhs.distanceFromCenter ?? .greatestFiniteMagnitude)
                    < (rhs.distanceFromCenter ?? .greatestFiniteMagnitude)
            }

        return self.selectDiverseActivities(from: scored, limit: limit)
    }
}

private extension CityActivityRanking {
    struct ConsolidatedActivity: Sendable {
        let activity: CityActivity
        let supportingSourceNames: Set<String>
        let metadataRichnessScore: Int
        let practicalInfoCount: Int
    }

    enum CategoryGroup: Sendable {
        case signature
        case experiential
        case supporting
    }

    static func consolidatedActivities(from activities: [CityActivity]) -> [ConsolidatedActivity] {
        let grouped = Dictionary(grouping: activities) {
            self.normalizedActivityName($0.name)
        }

        return grouped.values.compactMap { group in
            guard !group.isEmpty else { return nil }

            let sortedGroup = group.sorted { lhs, rhs in
                self.mergePreferenceScore(lhs) > self.mergePreferenceScore(rhs)
            }

            guard var merged = sortedGroup.first else { return nil }

            for activity in sortedGroup.dropFirst() {
                merged = self.mergedActivity(preferred: merged, supplemental: activity)
            }

            return ConsolidatedActivity(
                activity: merged,
                supportingSourceNames: Set(group.map(\.sourceName)),
                metadataRichnessScore: self.metadataRichnessScore(for: merged),
                practicalInfoCount: self.practicalInfoCount(for: merged)
            )
        }
    }

    static func score(
        _ consolidated: ConsolidatedActivity,
        cityCoordinate: CLLocationCoordinate2D
    ) -> ScoredActivity {
        var signals: [Signal] = []
        var score = 0

        score += self.scoreSourceConfidence(consolidated, signals: &signals)
        score += self.scoreMetadata(consolidated, signals: &signals)
        score += self.scoreCategoryAppeal(consolidated.activity, signals: &signals)

        let distanceFromCenter = self.distance(
            from: cityCoordinate,
            latitude: consolidated.activity.latitude,
            longitude: consolidated.activity.longitude
        )
        score += self.scoreLocation(distanceFromCenter, signals: &signals)
        score += self.scorePenalties(consolidated)

        return ScoredActivity(
            activity: consolidated.activity,
            baseScore: score,
            topSignals: signals.sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                return String(describing: lhs) < String(describing: rhs)
            },
            distanceFromCenter: distanceFromCenter,
            primaryCategoryKey: self.normalizedCategoryKey(consolidated.activity.category)
        )
    }

    static func scoreSourceConfidence(
        _ consolidated: ConsolidatedActivity,
        signals: inout [Signal]
    ) -> Int {
        var score = 0

        switch consolidated.supportingSourceNames.count {
        case 3...:
            signals.append(.crossSourceConfirmed)
            score += Signal.crossSourceConfirmed.points + 2
        case 2:
            signals.append(.crossSourceConfirmed)
            score += Signal.crossSourceConfirmed.points
        default:
            break
        }

        if consolidated.supportingSourceNames.contains("Wikivoyage") {
            signals.append(.editorialGuide)
            score += Signal.editorialGuide.points
        } else if consolidated.supportingSourceNames.contains("OpenStreetMap") {
            score += 6
        } else if consolidated.supportingSourceNames.contains("Wikipedia") {
            score += 5
        }

        return score
    }

    static func scoreMetadata(
        _ consolidated: ConsolidatedActivity,
        signals: inout [Signal]
    ) -> Int {
        let activity = consolidated.activity
        var score = 0

        if consolidated.practicalInfoCount >= 3 {
            signals.append(.practicalInfoRich)
            score += Signal.practicalInfoRich.points
        } else if consolidated.practicalInfoCount == 2 {
            score += 5
        } else if consolidated.practicalInfoCount == 1 {
            score += 2
        }

        if activity.officialURL != nil { score += 5 }
        if activity.sourceURL != nil { score += 3 }
        if activity.wikidataIdentifier != nil { score += 4 }

        if activity.imageURL != nil {
            signals.append(.visualReference)
            score += Signal.visualReference.points
        }

        if activity.latitude != nil, activity.longitude != nil {
            signals.append(.locationPinned)
            score += Signal.locationPinned.points
        }

        if consolidated.metadataRichnessScore >= 8 {
            score += 4
        } else if consolidated.metadataRichnessScore >= 5 {
            score += 2
        }

        score += min(activity.summary.count, 280) / 24
        return score
    }

    static func scoreCategoryAppeal(
        _ activity: CityActivity,
        signals: inout [Signal]
    ) -> Int {
        switch self.categoryGroup(for: activity) {
        case .signature:
            signals.append(.signatureAttraction)
            return Signal.signatureAttraction.points
        case .experiential:
            signals.append(.experientialPick)
            return Signal.experientialPick.points
        case .supporting:
            return 4
        }
    }

    static func scoreLocation(
        _ distanceFromCenter: CLLocationDistance?,
        signals: inout [Signal]
    ) -> Int {
        guard let distanceFromCenter else { return 0 }

        if distanceFromCenter < 2_500 {
            signals.append(.centralLocation)
            return Signal.centralLocation.points
        } else if distanceFromCenter < 7_500 {
            signals.append(.centralLocation)
            return 2
        } else if distanceFromCenter < 15_000 {
            return 1
        }

        return 0
    }

    static func scorePenalties(_ consolidated: ConsolidatedActivity) -> Int {
        let activity = consolidated.activity
        var penalty = 0

        if consolidated.supportingSourceNames.count == 1,
           self.normalizedCategoryKey(activity.category) == "attraction",
           activity.summary.count < 90
        {
            penalty -= 4
        }

        let lacksContext = activity.officialURL == nil
            && activity.sourceURL == nil
            && activity.imageURL == nil
            && activity.latitude == nil
            && activity.longitude == nil
            && consolidated.practicalInfoCount == 0

        if lacksContext, activity.summary.count < 80 {
            penalty -= 6
        }

        return penalty
    }

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

        adjustedScore += seenCategories.contains(candidate.primaryCategoryKey) ? -3 : 5

        let currentKindCount = kindCounts[candidate.activity.kind, default: 0]
        let otherKind: CityActivity.Kind = candidate.activity.kind == .see ? .do : .see
        let otherKindCount = kindCounts[otherKind, default: 0]
        if currentKindCount <= otherKindCount {
            adjustedScore += 2
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
