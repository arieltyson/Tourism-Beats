import SwiftUI

// MARK: - ReducedMotionModifier

/// A view modifier that respects the Reduce Motion accessibility setting.
struct ReducedMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: V
    let standardAnimation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content.animation(
            self.reduceMotion ? self.reducedAnimation : self.standardAnimation,
            value: self.value
        )
    }
}

extension View {
    /// Applies an animation that automatically degrades for Reduce Motion users.
    func motionSensitiveAnimation(
        _ standard: Animation,
        reduced: Animation = .default.speed(2),
        value: some Equatable
    ) -> some View {
        modifier(
            ReducedMotionModifier(
                value: value,
                standardAnimation: standard,
                reducedAnimation: reduced
            )
        )
    }
}
