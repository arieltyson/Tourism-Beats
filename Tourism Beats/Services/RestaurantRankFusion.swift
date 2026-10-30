import Foundation

// MARK: - RestaurantRankFusion

/// Combines where a restaurant appears across several Apple Maps searches
/// into one consensus score, using reciprocal rank fusion (Cormack, Clarke &
/// Büttcher, 2009): each search adds `weight / (smoothing + position)`.
///
/// Apple Maps orders results using ratings and review volume it doesn't
/// expose, so a place that sits near the top of many searches, especially
/// the rating-focused ones, is the best free stand-in for a highly rated,
/// widely reviewed restaurant. Every position counts, and consistency across
/// searches outweighs one lucky appearance.
enum RestaurantRankFusion {
    struct Query: Sendable {
        let text: String
        /// Searches that ask for the best or top-rated places say the most
        /// about quality, so they count for more.
        let weight: Double
        /// Searches about the food itself rather than general popularity.
        let isFoodQuality: Bool
    }

    /// Searches that ask for quality count this much more than general ones.
    static let qualityQueryWeight: Double = 2
    static let generalQueryWeight: Double = 1

    /// Keeps the gap between neighbouring positions meaningful. Lower than the
    /// customary 60 because each search returns at most a few dozen places,
    /// so being first rather than tenth should matter.
    static let smoothing: Double = 5

    static func queries(forCityNamed cityName: String) -> [Query] {
        [
            Query(text: "top rated restaurants", weight: self.qualityQueryWeight, isFoodQuality: false),
            Query(text: "best restaurants", weight: self.qualityQueryWeight, isFoodQuality: false),
            Query(text: "restaurants", weight: self.generalQueryWeight, isFoodQuality: false),
            Query(text: "popular restaurants", weight: self.generalQueryWeight, isFoodQuality: false),
            Query(text: "best food \(cityName)", weight: self.qualityQueryWeight, isFoodQuality: true),
            Query(text: "fine dining", weight: self.generalQueryWeight, isFoodQuality: true),
            Query(text: "authentic local cuisine", weight: self.generalQueryWeight, isFoodQuality: true)
        ]
    }

    /// What one appearance adds, for a 1-based position in a search.
    static func contribution(position: Int, weight: Double) -> Double {
        weight / (self.smoothing + Double(position))
    }

    /// The fused total of a restaurant that is first in every search.
    static var perfectTotal: Double {
        self.queries(forCityNamed: "").reduce(0) {
            $0 + self.contribution(position: 1, weight: $1.weight)
        }
    }

    /// Scales a fused total to 0...1, where 1 means first in every search.
    static func normalized(_ total: Double) -> Double {
        min(total / self.perfectTotal, 1)
    }

    /// The consensus for a restaurant known only by its best position, as
    /// when Apple Maps' per-search order isn't available: one appearance in
    /// one general search.
    static func consensus(forSinglePosition position: Int) -> Double {
        self.normalized(self.contribution(position: position, weight: self.generalQueryWeight))
    }
}
