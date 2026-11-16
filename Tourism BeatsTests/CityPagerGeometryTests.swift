import CoreGraphics
import Testing
@testable import Tourism_Beats

// MARK: - CityPagerGeometryTests

struct CityPagerGeometryTests {
    private static let pageHeight: CGFloat = 874

    @Test(arguments: [
        (CGFloat(0), 0),
        (CGFloat(436), 0),
        (CGFloat(438), 1),
        (CGFloat(874), 1),
        (CGFloat(1_757.67), 2)
    ])
    func thePageChangesOnceASwipeCrossesMidway(offset: CGFloat, page: Int) {
        #expect(CityPagerGeometry.page(atOffset: offset, pageHeight: Self.pageHeight, pageCount: 5) == page)
    }

    @Test func bouncingPastEitherEndStaysOnTheEndPage() {
        #expect(CityPagerGeometry.page(atOffset: -120, pageHeight: Self.pageHeight, pageCount: 5) == 0)
        #expect(CityPagerGeometry.page(atOffset: 5_000, pageHeight: Self.pageHeight, pageCount: 5) == 4)
    }

    @Test func anUnmeasuredPagerShowsTheFirstPage() {
        #expect(CityPagerGeometry.page(atOffset: 300, pageHeight: 0, pageCount: 5) == 0)
    }
}
