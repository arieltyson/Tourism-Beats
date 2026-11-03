import SwiftUI

struct FlightProgressLayout: Layout {
    let progress: Double
    let rightToLeft: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? FlightProgressTokens.idealWidth,
               height: subviews.last?.sizeThatFits(.unspecified).height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 4 else { return }
        let plane = subviews[3].sizeThatFits(.unspecified)
        let inset = min(bounds.width / 2, plane.width / 2)
        let width = max(0, bounds.width - inset * 2)
        subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                          proposal: ProposedViewSize(width: width, height: FlightProgressTokens.lineWidth))
        for index in 1...2 {
            subviews[index].place(at: CGPoint(x: bounds.minX + inset + (index == 2 ? width : 0), y: bounds.midY),
                                 anchor: .center, proposal: .unspecified)
        }
        let position = rightToLeft ? 1 - progress : progress
        subviews[3].place(at: CGPoint(x: bounds.minX + inset + width * position, y: bounds.midY),
                         anchor: .center, proposal: .unspecified)
    }
}
