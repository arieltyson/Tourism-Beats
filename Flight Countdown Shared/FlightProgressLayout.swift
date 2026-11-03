import SwiftUI

/// Lays out the route: the flown and remaining line, both endpoints, and the
/// plane between them. The line stops short of the plane rather than running
/// beneath it, so the track reads on any background, photos included.
///
/// Subviews, in order: flown line, remaining line, origin, destination, plane.
struct FlightProgressLayout: Layout {
    let progress: Double
    let rightToLeft: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // An unbounded proposal asks for the maximum size; the track has none.
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? FlightProgressTokens.idealWidth
        return CGSize(width: width, height: subviews.last?.sizeThatFits(.unspecified).height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 5 else { return }
        let plane = subviews[4].sizeThatFits(.unspecified)
        let inset = min(bounds.width / 2, plane.width / 2)
        let start = bounds.minX + inset
        let end = bounds.maxX - inset
        let planeX = start + (end - start) * (rightToLeft ? 1 - progress : progress)
        let gap = plane.width / 2 + FlightProgressTokens.planeClearance
        let leading = (from: start, to: max(start, planeX - gap))
        let trailing = (from: min(end, planeX + gap), to: end)
        let (flown, remaining) = rightToLeft ? (trailing, leading) : (leading, trailing)
        for (index, segment) in [flown, remaining].enumerated() {
            subviews[index].place(
                at: CGPoint(x: segment.from, y: bounds.midY), anchor: .leading,
                proposal: ProposedViewSize(width: segment.to - segment.from, height: FlightProgressTokens.lineWidth)
            )
        }
        let (origin, destination) = rightToLeft ? (end, start) : (start, end)
        subviews[2].place(at: CGPoint(x: origin, y: bounds.midY), anchor: .center, proposal: .unspecified)
        subviews[3].place(at: CGPoint(x: destination, y: bounds.midY), anchor: .center, proposal: .unspecified)
        subviews[4].place(at: CGPoint(x: planeX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}
