import Testing
@testable import Tourism_Beats

// MARK: - RestaurantRankFusionTests

struct RestaurantRankFusionTests {
    private static let queries = RestaurantRankFusion.queries(forCityNamed: "Lisbon")

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
        #expect(Self.queries.contains { $0.text == "top rated restaurants" && $0.weight == RestaurantRankFusion.qualityQueryWeight })
    }

    @Test func singlePositionFallbackIsOneAppearanceNotAPerfectScore() {
        let fallback = RestaurantRankFusion.consensus(forSinglePosition: 1)

        #expect(fallback > 0)
        #expect(fallback < 0.5)
    }
}
