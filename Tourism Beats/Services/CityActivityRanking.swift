import CoreLocation
import Foundation

// MARK: - CityActivityRanking

enum CityActivityRanking {
    struct ActivityDemandSignal: Sendable {
        var popularityRank: Int?
        var crossQueryAppearanceCount: Int = 0
        var reviewQueryAppearanceCount: Int = 0
        var pageviewCount: Int?
        var pageviewRank: Int?

        var hasDemandEvidence: Bool {
            self.popularityRank != nil
                || self.crossQueryAppearanceCount > 0
                || self.reviewQueryAppearanceCount > 0
                || self.pageviewCount != nil
        }
    }

    struct ScoredActivity: Sendable {
        let activity: CityActivity
        let baseScore: Int
        let topSignals: [Signal]
        let distanceFromCenter: CLLocationDistance?
        let primaryCategoryKey: String
    }

    enum Signal: Sendable {
        case popularChoice
        case reviewBacked
        case demonstratedDemand
        case editorialGuide
        case crossSourceConfirmed
        case practicalInfoRich
        case signatureAttraction
        case visualReference
        case locationPinned
        case centralLocation

        var points: Int {
            switch self {
            case .popularChoice:
                18
            case .reviewBacked:
                16
            case .demonstratedDemand:
                14
            case .editorialGuide:
                6
            case .crossSourceConfirmed:
                8
            case .practicalInfoRich:
                5
            case .signatureAttraction:
                4
            case .visualReference:
                3
            case .locationPinned:
                2
            case .centralLocation:
                1
            }
        }
    }

    static func activityKey(for name: String) -> String {
        self.normalizedActivityName(name)
    }

    static func topActivities(
        from activities: [CityActivity],
        for city: CityModel,
        demandSignals: [String: ActivityDemandSignal] = [:],
        limit: Int = 6
    ) -> [CityActivity] {
        let scored = self
            .consolidatedActivities(from: activities, demandSignals: demandSignals)
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
