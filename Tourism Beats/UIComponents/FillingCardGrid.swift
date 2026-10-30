import SwiftUI

// MARK: - FillingCardGrid

/// A grid that fills the space it's given with as many rows of cards as fit,
/// so taller screens show more and nothing is cut off. Larger text sizes
/// leave less room above the grid, so fewer rows fit.
///
/// At accessibility text sizes, a screenful would hold only a card or two
/// with titles cut to a word, so it becomes a single column of every card
/// instead, for a page that scrolls (see `scrollsAtAccessibilitySizes()`).
///
/// In the grid, cards take their height from it; see `CardGridLayout`.
struct FillingCardGrid<Card: View>: View {
    /// How many cards there are to show, or `nil` to fill every slot that
    /// fits, as loading placeholders do.
    let itemCount: Int?
    @ViewBuilder let card: (Int) -> Card

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var availableSize: CGSize?

    /// Loading placeholders shown in the single column, enough to fill it.
    private static var accessibilityPlaceholderCount: Int {
        CardGridLayout.columnCount
    }

    private static var spacing: CGFloat {
        SpacingTokens.small
    }

    init(itemCount: Int? = nil, @ViewBuilder card: @escaping (Int) -> Card) {
        self.itemCount = itemCount
        self.card = card
    }

    var body: some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            LazyVStack(spacing: Self.spacing) {
                ForEach(0 ..< (self.itemCount ?? Self.accessibilityPlaceholderCount), id: \.self) { index in
                    self.card(index)
                        .aspectRatio(CardGridLayout.preferredAspectRatio, contentMode: .fit)
                }
            }
        } else {
            self.fillingGrid
        }
    }

    private var layout: CardGridLayout? {
        self.availableSize.map { CardGridLayout(size: $0, spacing: Self.spacing) }
    }

    private var visibleCount: Int {
        guard let layout else { return 0 }
        return min(self.itemCount ?? layout.cardCount, layout.cardCount)
    }

    private var fillingGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: Self.spacing),
                count: CardGridLayout.columnCount
            ),
            spacing: Self.spacing
        ) {
            if let layout {
                ForEach(0 ..< self.visibleCount, id: \.self) { index in
                    self.card(index)
                        .frame(height: layout.cardHeight)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGSize.self, of: \.size) { size in
            self.availableSize = size
        }
    }
}
