import CoreGraphics
import Foundation

// MARK: - ClockDialLayout

/// The geometry of the clock's dial, for a dial of a given size.
///
/// Every position is relative to the dial's center, with y growing downward.
struct ClockDialLayout {
    let radius: CGFloat

    init(size: CGSize) {
        self.radius = min(size.width, size.height) / 2
    }

    /// The numerals' point size.
    var numeralSize: CGFloat {
        self.radius * ClockFaceTokens.numeralSize
    }

    /// How far from the center each tick's outer end sits.
    var tickOuterRadius: CGFloat {
        self.radius * (1 - ClockFaceTokens.tickInset)
    }

    /// How far from the center each tick's inner end sits.
    var tickInnerRadius: CGFloat {
        self.tickOuterRadius - self.radius * ClockFaceTokens.tickLength
    }

    /// The farthest any part of a numeral may reach from the center.
    var numeralReach: CGFloat {
        self.tickInnerRadius - self.radius * ClockFaceTokens.numeralGap
    }

    /// The unit vector from the center toward a position on the dial, where
    /// a full turn is `divisions` steps, clockwise from twelve.
    static func direction(at step: Int, of divisions: Int) -> CGVector {
        let radians = Double(step) / Double(divisions) * 2 * .pi
        return CGVector(dx: sin(radians), dy: -cos(radians))
    }

    /// The center of a numeral of the given size, pushed out as far as it
    /// goes while its farthest corner stays inside ``numeralReach``.
    ///
    /// Wide numerals such as 10 and 2 sit nearer the center than narrow ones,
    /// so every numeral keeps the same clear space from the ticks.
    func numeralCenter(forHour hour: Int, size: CGSize) -> CGPoint {
        let direction = Self.direction(at: hour, of: 12)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let corners = [
            CGVector(dx: halfWidth, dy: halfHeight),
            CGVector(dx: -halfWidth, dy: halfHeight),
            CGVector(dx: halfWidth, dy: -halfHeight),
            CGVector(dx: -halfWidth, dy: -halfHeight),
        ]

        // A corner k from the numeral's center d · u lies at distance R when
        // d² + 2d(u·k) + |k|² = R². The nearest of those d keeps all four in.
        let reach = self.numeralReach
        let distance = corners.map { corner in
            let along = direction.dx * corner.dx + direction.dy * corner.dy
            let squaredLength = corner.dx * corner.dx + corner.dy * corner.dy
            return -along + (along * along - squaredLength + reach * reach).squareRoot()
        }
        .min() ?? 0

        let clamped = max(distance, 0)
        return CGPoint(x: direction.dx * clamped, y: direction.dy * clamped)
    }
}
