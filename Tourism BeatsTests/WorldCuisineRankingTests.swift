import Foundation
import Testing
@testable import Tourism_Beats

struct WorldCuisineRankingTests {
    @Test func theTopFiveAreRankedInOrder() {
        let cuisines = WorldCuisineRanking.top
        #expect(cuisines.map(\.rank) == Array(1...5))
        #expect(Set(cuisines.map(\.name)).count == cuisines.count)
        #expect(cuisines.first?.name == "Italian")
    }

    @Test func everyCuisineHasASecurePhotoAndADish() {
        for cuisine in WorldCuisineRanking.top {
            #expect(cuisine.imageURL?.scheme == "https")
            #expect(!cuisine.signatureDish.isEmpty && !cuisine.flag.isEmpty)
        }
    }

    @Test func eachCardIsSpokenAsOne() {
        let label = WorldCuisineRanking.top[0].accessibilityLabel
        #expect(label.contains("1") && label.contains("Italian") && label.contains("Pizza napoletana"))
    }
}
