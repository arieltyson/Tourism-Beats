import Testing
@testable import Tourism_Beats

// MARK: - CityPagerLoadingTests

struct CityPagerLoadingTests {
    private static let pageCount = 5

    @Test(arguments: [
        (0, Set([0, 1])),
        (2, Set([1, 2, 3])),
        (4, Set([3, 4]))
    ])
    func buildsTheSettledPageAndItsNeighbors(index: Int, expected: Set<Int>) {
        #expect(CityPagerLoading.pages(around: index, pageCount: Self.pageCount) == expected)
    }

    @Test func everyNeighborOfASettledPageIsReadyForTheNextSwipe() {
        for index in 0 ..< Self.pageCount {
            let pages = CityPagerLoading.pages(around: index, pageCount: Self.pageCount)
            #expect(pages.contains(index))
            #expect(index == 0 || pages.contains(index - 1))
            #expect(index == Self.pageCount - 1 || pages.contains(index + 1))
        }
    }
}
