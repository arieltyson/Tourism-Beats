import SwiftUI

// MARK: - ClockPin

/// A disc at the clock's center: the hub the hands turn on, or a cap over it.
struct ClockPin: Shape {
    /// The disc's diameter, as a fraction of the dial's radius.
    let diameter: CGFloat

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) / 2 * self.diameter
        return Circle().path(in: CGRect(
            x: rect.midX - side / 2,
            y: rect.midY - side / 2,
            width: side,
            height: side
        ))
    }
}
