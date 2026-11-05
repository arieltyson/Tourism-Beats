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
///
/// Apple Maps matches a search's words against place names as well as
/// reputation, so a search that finds almost nothing has matched names, not
/// quality: in London, "best food" finds only a takeaway called "Best
/// Chinese Food". Only searches that return a real list count, and scores
/// are measured against those alone.
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

    /// Fewer results than this is a match on names, not a ranking.
    static let minimumRankedResults = 5

    /// Plain nouns return full, reputation-ordered lists in cities of every
    /// size; adjectives such as "top rated" or "popular" mostly match names.
    /// Kept to seven so a city's searches stay within Apple Maps' limits.
    static let queries: [Query] = [
        Query(text: "restaurants", weight: generalQueryWeight, isFoodQuality: false),
        Query(text: "restaurant", weight: generalQueryWeight, isFoodQuality: false),
        Query(text: "dinner", weight: generalQueryWeight, isFoodQuality: false),
        Query(text: "food", weight: generalQueryWeight, isFoodQuality: true),
        Query(text: "best restaurants", weight: qualityQueryWeight, isFoodQuality: false),
        Query(text: "fine dining", weight: qualityQueryWeight, isFoodQuality: true),
        Query(text: "michelin", weight: qualityQueryWeight, isFoodQuality: true),
    ]

    /// Which searches returned a real ranking, given each one's result count.
    /// Where none did, as in a small town, every search that found anything
    /// counts, since that's all there is.
    static func ranks(resultCounts: [Int]) -> [Bool] {
        let ranked = resultCounts.map { $0 >= self.minimumRankedResults }
        return ranked.contains(true) ? ranked : resultCounts.map { $0 > 0 }
    }

    /// What one appearance adds, for a 1-based position in a search.
    static func contribution(position: Int, weight: Double) -> Double {
        weight / (self.smoothing + Double(position))
    }

    /// The fused total of a restaurant that is first in every one of `queries`.
    static func perfectTotal(over queries: [Query] = queries) -> Double {
        queries.reduce(0) { $0 + self.contribution(position: 1, weight: $1.weight) }
    }

    /// Scales a fused total to 0...1, where 1 means first in every one of
    /// `queries`, the searches that returned a ranking.
    static func normalized(_ total: Double, over queries: [Query] = queries) -> Double {
        let perfect = self.perfectTotal(over: queries)
        return perfect > 0 ? min(total / perfect, 1) : 0
    }

    /// The consensus for a restaurant known only by its best position, as
    /// when Apple Maps' per-search order isn't available: one appearance in
    /// one general search.
    static func consensus(forSinglePosition position: Int) -> Double {
        self.normalized(self.contribution(position: position, weight: self.generalQueryWeight))
    }
}
