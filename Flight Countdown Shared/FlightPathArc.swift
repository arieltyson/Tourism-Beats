import SwiftUI

/// The geometry of ``FlightPathGlyph``: a quadratic arc split exactly where
/// the plane is, so the flown line always ends under it.
struct FlightPathArc {
    let origin: CGPoint
    let destination: CGPoint
    /// Where the plane sits on the arc.
    let plane: CGPoint
    /// The direction of travel at the plane.
    let heading: Angle
    let flown: Path
    let remaining: Path

    init(size: CGSize, progress: Double) {
        let inset = size.height * FlightPathGlyphTokens.insetRatio
        let baseline = size.height - inset
        // A quadratic's apex rises half as far as its control point.
        let control = CGPoint(x: size.width / 2, y: baseline - 2 * size.height * FlightPathGlyphTokens.riseRatio)
        origin = CGPoint(x: inset, y: baseline)
        destination = CGPoint(x: size.width - inset, y: baseline)
        let t = min(1, max(0, progress))
        // de Casteljau: the two inner points are the halves' control points.
        let towardControl = origin.interpolated(to: control, by: t)
        let fromControl = control.interpolated(to: destination, by: t)
        plane = towardControl.interpolated(to: fromControl, by: t)
        heading = .radians(atan2(fromControl.y - towardControl.y, fromControl.x - towardControl.x))
        flown = Path { [origin, plane] path in
            path.move(to: origin)
            path.addQuadCurve(to: plane, control: towardControl)
        }
        remaining = Path { [plane, destination] path in
            path.move(to: plane)
            path.addQuadCurve(to: destination, control: fromControl)
        }
    }
}

extension CGPoint {
    func interpolated(to other: CGPoint, by fraction: CGFloat) -> CGPoint {
        CGPoint(x: x + (other.x - x) * fraction, y: y + (other.y - y) * fraction)
    }

    /// A square centred here, for drawing a dot of `radius`.
    func square(radius: CGFloat) -> CGRect {
        CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
    }
}
