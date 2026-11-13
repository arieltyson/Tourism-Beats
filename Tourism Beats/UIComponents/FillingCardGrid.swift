import SwiftUI

// MARK: - FillingCardGrid

/// A grid that fills the space it's given with as many rows and columns of
/// cards as fit, so taller and wider screens show more and nothing is cut off. Larger text sizes
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

    /// Loading placeholders shown in the single column, enough to fill it.
    private static var accessibilityPlaceholderCount: Int {
        CardGridLayout.minimumColumnCount
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
            // The card count depends on both dimensions. Read the proposal
            // directly so the pager never observes an empty measuring pass.
            GeometryReader { geometry in
                let layout = CardGridLayout(size: geometry.size, spacing: Self.spacing)
                let visibleCount = min(self.itemCount ?? layout.cardCount, layout.cardCount)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: Self.spacing),
                        count: layout.columnCount
                    ),
                    spacing: Self.spacing
                ) {
                    ForEach(0 ..< visibleCount, id: \.self) { index in
                        self.card(index)
                            .frame(height: layout.cardHeight)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}
