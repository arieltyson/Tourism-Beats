import CoreLocation
import Foundation

extension CityActivityRanking {
    struct ConsolidatedActivity: Sendable {
        let activity: CityActivity
        let demandSignal: ActivityDemandSignal
        let supportingSourceNames: Set<String>
        let metadataRichnessScore: Int
        let practicalInfoCount: Int
    }

    enum CategoryGroup: Sendable {
        case signature
        case experiential
        case supporting
    }

    static func consolidatedActivities(
        from activities: [CityActivity],
        demandSignals: [String: ActivityDemandSignal]
    ) -> [ConsolidatedActivity] {
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
                demandSignal: demandSignals[self.normalizedActivityName(merged.name)] ?? ActivityDemandSignal(),
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

        score += self.scoreDemand(consolidated.demandSignal, signals: &signals)
        score += self.scoreSourceConfidence(consolidated, signals: &signals)
        score += self.scoreMetadata(consolidated, signals: &signals)
        score += self.scoreCategoryAppeal(
            consolidated.activity,
            hasDemandEvidence: consolidated.demandSignal.hasDemandEvidence,
            signals: &signals
        )

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

    static func scoreDemand(
        _ demandSignal: ActivityDemandSignal,
        signals: inout [Signal]
    ) -> Int {
        var score = 0

        if let rank = demandSignal.popularityRank {
            switch rank {
            case 1 ... 5:
                signals.append(.popularChoice)
                score += Signal.popularChoice.points
            case 6 ... 10:
                signals.append(.popularChoice)
                score += 13
            case 11 ... 20:
                score += 8
            default:
                score += 4
            }
        }

        if demandSignal.crossQueryAppearanceCount >= 4 {
            signals.append(.popularChoice)
            score += 14
        } else if demandSignal.crossQueryAppearanceCount == 3 {
            signals.append(.popularChoice)
            score += 11
        } else if demandSignal.crossQueryAppearanceCount == 2 {
            score += 7
        }

        if demandSignal.reviewQueryAppearanceCount >= 2 {
            signals.append(.reviewBacked)
            score += Signal.reviewBacked.points
        } else if demandSignal.reviewQueryAppearanceCount == 1 {
            signals.append(.reviewBacked)
            score += 9
        }

        if let pageviewRank = demandSignal.pageviewRank {
            switch pageviewRank {
            case 1 ... 2:
                signals.append(.demonstratedDemand)
                score += Signal.demonstratedDemand.points
            case 3 ... 5:
                signals.append(.demonstratedDemand)
                score += 10
            case 6 ... 10:
                score += 6
            default:
                score += 3
            }
        }

        return score
    }

    static func scoreSourceConfidence(
        _ consolidated: ConsolidatedActivity,
        signals: inout [Signal]
    ) -> Int {
        var score = 0

        switch consolidated.supportingSourceNames.count {
        case 3...:
            signals.append(.crossSourceConfirmed)
            score += Signal.crossSourceConfirmed.points
        case 2:
            signals.append(.crossSourceConfirmed)
            score += 5
        default:
            break
        }

        if consolidated.supportingSourceNames.contains("Wikivoyage") {
            signals.append(.editorialGuide)
            score += Signal.editorialGuide.points
        } else if consolidated.supportingSourceNames.contains("OpenStreetMap") {
            score += 4
        } else if consolidated.supportingSourceNames.contains("Wikipedia") {
            score += 3
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
            score += 3
        } else if consolidated.practicalInfoCount == 1 {
            score += 1
        }

        if activity.officialURL != nil { score += 3 }
        if activity.sourceURL != nil { score += 2 }
        if activity.wikidataIdentifier != nil { score += 2 }

        if activity.imageURL != nil {
            signals.append(.visualReference)
            score += Signal.visualReference.points
        }

        if activity.latitude != nil, activity.longitude != nil {
            signals.append(.locationPinned)
            score += Signal.locationPinned.points
        }

        if consolidated.metadataRichnessScore >= 8 {
            score += 2
        } else if consolidated.metadataRichnessScore >= 5 {
            score += 1
        }

        score += min(activity.summary.count, 280) / 56
        return score
    }

    static func scoreCategoryAppeal(
        _ activity: CityActivity,
        hasDemandEvidence: Bool,
        signals: inout [Signal]
    ) -> Int {
        switch self.categoryGroup(for: activity) {
        case .signature:
            signals.append(.signatureAttraction)
            return hasDemandEvidence ? Signal.signatureAttraction.points : 6
        case .experiential:
            return hasDemandEvidence ? 2 : 4
        case .supporting:
            return hasDemandEvidence ? 1 : 2
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
            return 1
        } else if distanceFromCenter < 15_000 {
            return 0
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
}
