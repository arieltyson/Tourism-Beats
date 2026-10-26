import SwiftUI

// MARK: - TripHeroMinimumHeightLayout

/// Sizes its content to at least `minHeight`, then offers the content that
/// final height so spacers can push the badges to the top of the card.
struct TripHeroMinimumHeightLayout: Layout {
    let minHeight: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let idealSize = subviews.first?.sizeThatFits(
            ProposedViewSize(width: proposal.width, height: nil)
        ) ?? .zero

        return CGSize(
            width: proposal.width ?? idealSize.width,
            height: max(self.minHeight, idealSize.height)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(bounds.size)
        )
    }
}
