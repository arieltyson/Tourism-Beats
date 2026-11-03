import CoreGraphics

/// How a photo sits in its frame: the point of it kept centred, and how far
/// it's zoomed in past filling the frame.
///
/// Framing is independent of the frame's shape, so one choice serves the
/// in-app card and every widget size. Where a frame can't centre the point
/// without showing an edge, the photo stops at the edge instead.
struct FlightPhotoFraming: Codable, Hashable, Sendable {
    /// The point of the photo kept centred, from 0 to 1 across each axis.
    var focusX: Double = 0.5
    var focusY: Double = 0.5
    /// 1 fills the frame; larger values zoom in.
    var zoom: Double = 1

    /// The photo filling its frame, centred.
    static let centered = Self()
    static let zoomRange: ClosedRange<Double> = 1...4

    var isCentered: Bool { self == .centered }

    /// Where the photo is drawn within a frame of `frameSize`, in the
    /// frame's coordinates. The photo always covers the frame.
    func rect(for imageSize: CGSize, in frameSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return CGRect(origin: .zero, size: frameSize) }
        let fill = max(frameSize.width / imageSize.width, frameSize.height / imageSize.height)
        let scale = fill * Self.zoomRange.clamped(zoom)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: Self.origin(centering: focusX, of: size.width, in: frameSize.width),
            y: Self.origin(centering: focusY, of: size.height, in: frameSize.height)
        )
        return CGRect(origin: origin, size: size)
    }

    /// The framing after dragging the photo by `translation` in a frame of
    /// `frameSize`. The focus settles where the photo actually stops, so
    /// dragging past an edge doesn't build up hidden travel.
    func moved(by translation: CGSize, imageSize: CGSize, frameSize: CGSize) -> Self {
        let current = rect(for: imageSize, in: frameSize)
        guard current.width > 0, current.height > 0 else { return self }
        let origin = CGPoint(
            x: Self.clampedOrigin(current.minX + translation.width, of: current.width, in: frameSize.width),
            y: Self.clampedOrigin(current.minY + translation.height, of: current.height, in: frameSize.height)
        )
        var framing = self
        framing.focusX = (frameSize.width / 2 - origin.x) / current.width
        framing.focusY = (frameSize.height / 2 - origin.y) / current.height
        return framing
    }

    /// The framing zoomed by `magnification` about the centre of the frame.
    func zoomed(by magnification: Double) -> Self {
        var framing = self
        framing.zoom = Self.zoomRange.clamped(zoom * magnification)
        return framing
    }

    private static func origin(centering focus: Double, of length: CGFloat, in frame: CGFloat) -> CGFloat {
        clampedOrigin(frame / 2 - focus * length, of: length, in: frame)
    }

    /// Keeps the photo covering the frame along one axis.
    private static func clampedOrigin(_ origin: CGFloat, of length: CGFloat, in frame: CGFloat) -> CGFloat {
        min(0, max(frame - length, origin))
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}
