import CoreGraphics
import Testing
@testable import Tourism_Beats

// MARK: - CardGridLayoutTests

struct CardGridLayoutTests {
    private static let spacing: CGFloat = 12

    /// Two cards side by side in this width are 200 points wide each: 150
    /// tall at 4:3, between 133⅓ (3:2) and 166⅔ (6:5) as the grid allows.
    private static let width: CGFloat = 400 + spacing
    private static let cardWidth: CGFloat = 200

    @Test(arguments: [(640.0, 4), (720.0, 5)])
    func rowsFillTheHeightExactly(height: CGFloat, expectedRows: Int) {
        let layout = Self.layout(height: height)
        let usedHeight = layout.cardHeight * CGFloat(layout.rowCount)
            + Self.spacing * CGFloat(layout.rowCount - 1)

        #expect(layout.rowCount == expectedRows)
        #expect(abs(usedHeight - height) < 0.001)
    }

    @Test(arguments: [640.0, 700.0, 720.0])
    func cardsStayCloseToTheirShape(height: CGFloat) {
        let aspectRatio = Self.cardWidth / Self.layout(height: height).cardHeight

        #expect(aspectRatio >= CardGridLayout.tallestAspectRatio - 0.001)
        #expect(aspectRatio <= CardGridLayout.widestAspectRatio + 0.001)
    }

    @Test func gapTooBigToCloseLeavesCardsAtTheirDeepest() {
        let layout = Self.layout(height: 400)

        #expect(layout.rowCount == 2)
        #expect(abs(layout.cardHeight - Self.cardWidth / CardGridLayout.tallestAspectRatio) < 0.001)
    }

    @Test func tallerSpaceFitsMoreCards() {
        #expect(Self.layout(height: 720).cardCount > Self.layout(height: 480).cardCount)
    }

    @Test(arguments: [CGSize.zero, CGSize(width: 0, height: 500), CGSize(width: 400, height: 0)])
    func alwaysShowsAtLeastOneRow(size: CGSize) {
        #expect(CardGridLayout(size: size, spacing: Self.spacing).rowCount == 1)
    }

    private static func layout(height: CGFloat) -> CardGridLayout {
        CardGridLayout(size: CGSize(width: Self.width, height: height), spacing: Self.spacing)
    }
}
