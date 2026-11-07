import SwiftUI

// MARK: - ClockHand

/// One hand of the clock, pointing at twelve; rotate it to tell the time.
///
/// Every length is a fraction of the dial's radius, so the hand fits any
/// clock size. The hour and minute hands join the hub by a slim neck, and
/// the second hand runs back past the hub as a counterweight.
struct ClockHand: Shape {
    /// How far the hand reaches from the center.
    let length: CGFloat

    /// The width of the hand's broad part.
    let width: CGFloat

    /// The length of the slim neck between the hub and the broad part.
    var neckLength: CGFloat = 0

    /// The width of that neck.
    var neckWidth: CGFloat = 0

    /// How far the hand runs back past the center.
    var tail: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        if self.neckLength > 0 {
            let neckWidth = self.neckWidth * radius
            path.addPath(
                Capsule().path(in: CGRect(
                    x: center.x - neckWidth / 2,
                    y: center.y - self.neckLength * radius,
                    width: neckWidth,
                    height: self.neckLength * radius
                ))
            )
        }

        let width = self.width * radius
        let top = center.y - self.length * radius
        let bottom = center.y - self.neckLength * radius + self.tail * radius
        path.addPath(
            Capsule().path(in: CGRect(x: center.x - width / 2, y: top, width: width, height: bottom - top))
        )
        return path
    }
}

// MARK: - Hands

extension ClockHand {
    static let hour = ClockHand(
        length: ClockFaceTokens.hourHandLength,
        width: ClockFaceTokens.handWidth,
        neckLength: ClockFaceTokens.handNeckLength,
        neckWidth: ClockFaceTokens.handNeckWidth
    )

    static let minute = ClockHand(
        length: ClockFaceTokens.minuteHandLength,
        width: ClockFaceTokens.handWidth,
        neckLength: ClockFaceTokens.handNeckLength,
        neckWidth: ClockFaceTokens.handNeckWidth
    )

    static let second = ClockHand(
        length: ClockFaceTokens.secondHandLength,
        width: ClockFaceTokens.secondHandWidth,
        tail: ClockFaceTokens.secondHandTail
    )
}
