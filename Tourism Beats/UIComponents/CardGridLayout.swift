import CoreGraphics

// MARK: - CardGridLayout

/// Fits a two-column grid of landscape cards to a space: as many rows as fit,
/// with the cards stretched a little so the rows fill it exactly instead of
/// leaving a gap below the last one.
///
/// Cards keep close to their 4:3 shape. They may flatten to 3:2 to make room
/// for another row, or deepen to 6:5 to close a gap; a gap too big for that
/// stays, rather than turning the cards into towers.
struct CardGridLayout: Equatable {
    static let columnCount = 2

    /// The shape cards are designed around (width over height).
    static let preferredAspectRatio: CGFloat = 4 / 3

    /// The flattest a card may get (width over height) to fit another row.
    static let widestAspectRatio: CGFloat = 3 / 2

    /// The deepest a card may get (width over height) to fill leftover space.
    static let tallestAspectRatio: CGFloat = 6 / 5

    let rowCount: Int
    let cardHeight: CGFloat

    var cardCount: Int {
        self.rowCount * Self.columnCount
    }

    init(size: CGSize, spacing: CGFloat) {
        let columns = CGFloat(Self.columnCount)
        let cardWidth = max((size.width - spacing * (columns - 1)) / columns, 0)
        let shortestCard = cardWidth / Self.widestAspectRatio
        let tallestCard = cardWidth / Self.tallestAspectRatio

        guard shortestCard > 0, size.height > 0 else {
            self.rowCount = 1
            self.cardHeight = tallestCard
            return
        }

        // Each row after the first also needs the spacing above it.
        let fittingRows = ((size.height + spacing) / (shortestCard + spacing)).rounded(.down)
        let rowCount = max(Int(fittingRows), 1)
        let fillingHeight = (size.height - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)

        self.rowCount = rowCount
        self.cardHeight = min(fillingHeight, tallestCard)
    }
}
