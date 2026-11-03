import SwiftUI

/// Fills its proposed size and places its one subview, a photo, where its
/// framing puts it.
struct FlightPhotoFrameLayout: Layout {
    let imageSize: CGSize
    let framing: FlightPhotoFraming

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rect = framing.rect(for: imageSize, in: bounds.size)
        for subview in subviews {
            subview.place(
                at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(rect.size)
            )
        }
    }
}
