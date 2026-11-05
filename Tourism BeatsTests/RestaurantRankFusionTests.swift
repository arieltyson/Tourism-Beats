import Testing
@testable import Tourism_Beats

// MARK: - RestaurantRankFusionTests

struct RestaurantRankFusionTests {
    private static let queries = RestaurantRankFusion.queries

    @Test func firstInEverySearchIsAPerfectConsensus() {
        let total = Self.queries.reduce(0) {
            $0 + RestaurantRankFusion.contribution(position: 1, weight: $1.weight)
        }

        #expect(abs(RestaurantRankFusion.normalized(total) - 1) < 0.000_1)
    }

    @Test func everyPositionCounts() {
        let weight = RestaurantRankFusion.generalQueryWeight
        let positions = 1 ... 25
        let contributions = positions.map { RestaurantRankFusion.contribution(position: $0, weight: weight) }

        #expect(zip(contributions, contributions.dropFirst()).allSatisfy { $0 > $1 })
    }

    @Test func consistentlyNearTheTopBeatsOneLuckyFirstPlace() {
        let consistent = Self.queries.reduce(0) {
            $0 + RestaurantRankFusion.contribution(position: 3, weight: $1.weight)
        }
        let lucky = RestaurantRankFusion.contribution(
            position: 1,
            weight: RestaurantRankFusion.qualityQueryWeight
        )

        #expect(consistent > lucky)
    }

    @Test func qualitySearchesCountForMore() {
        let quality = RestaurantRankFusion.contribution(position: 5, weight: RestaurantRankFusion.qualityQueryWeight)
        let general = RestaurantRankFusion.contribution(position: 5, weight: RestaurantRankFusion.generalQueryWeight)

        #expect(quality > general)
        #expect(Self.queries.contains { $0.text == "fine dining" && $0.weight == RestaurantRankFusion.qualityQueryWeight })
    }

    @Test func singlePositionFallbackIsOneAppearanceNotAPerfectScore() {
        let fallback = RestaurantRankFusion.consensus(forSinglePosition: 1)

        #expect(fallback > 0)
        #expect(fallback < 0.5)
    }

    /// In London, "best food" found only a takeaway named "Best Chinese
    /// Food": too few results to be a ranking, so it takes no part.
    @Test func nearlyEmptySearchesAreNamesNotRankings() {
        #expect(RestaurantRankFusion.ranks(resultCounts: [25, 2, 0, 25]) == [true, false, false, true])
    }

    /// A small town where every search is sparse keeps what it found.
    @Test func aSmallTownKeepsItsSparseSearches() {
        #expect(RestaurantRankFusion.ranks(resultCounts: [3, 0, 2]) == [true, false, true])
    }

    /// First in every search that ranked anything is a perfect consensus,
    /// however many searches came back empty.
    @Test func consensusIsMeasuredAgainstTheSearchesThatRanked() {
        let ranked = Array(Self.queries.prefix(2))
        let total = ranked.reduce(0) { $0 + RestaurantRankFusion.contribution(position: 1, weight: $1.weight) }
        #expect(abs(RestaurantRankFusion.normalized(total, over: ranked) - 1) < 0.000_1)
    }
}
