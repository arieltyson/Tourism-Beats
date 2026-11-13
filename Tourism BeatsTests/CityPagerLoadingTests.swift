import Testing
@testable import Tourism_Beats

// MARK: - CityPagerLoadingTests

struct CityPagerLoadingTests {
    private static let pageCount = 5

    @Test(arguments: [
        (0, Set([0, 1, 2])),
        (2, Set([0, 1, 2, 3, 4])),
        (4, Set([2, 3, 4]))
    ])
    func buildsTheSettledPageAndThoseWithinReach(index: Int, expected: Set<Int>) {
        #expect(CityPagerLoading.pages(around: index, pageCount: Self.pageCount) == expected)
    }

    /// Two swipes in a row, with no rest between, still land on a built page.
    @Test func twoQuickSwipesEitherWayLandOnABuiltPage() {
        for index in 0 ..< Self.pageCount {
            let pages = CityPagerLoading.pages(around: index, pageCount: Self.pageCount)
            for destination in [index - 2, index - 1, index, index + 1, index + 2]
                where (0 ..< Self.pageCount).contains(destination)
            {
                #expect(pages.contains(destination))
            }
        }
    }

    @Test func prebuildingTakesTheClosestUnbuiltPageFurtherOnFirst() {
        #expect(CityPagerLoading.nextPageToPrebuild(around: 0, loadedPages: [0, 1, 2], pageCount: Self.pageCount) == 3)
        #expect(CityPagerLoading.nextPageToPrebuild(around: 2, loadedPages: [2], pageCount: Self.pageCount) == 3)
        #expect(CityPagerLoading.nextPageToPrebuild(around: 4, loadedPages: [2, 3, 4], pageCount: Self.pageCount) == 1)
    }

    @Test func prebuildingStopsOnceEveryPageIsBuilt() {
        let everyPage = Set(0 ..< Self.pageCount)
        #expect(CityPagerLoading.nextPageToPrebuild(around: 1, loadedPages: everyPage, pageCount: Self.pageCount) == nil)
    }
}
