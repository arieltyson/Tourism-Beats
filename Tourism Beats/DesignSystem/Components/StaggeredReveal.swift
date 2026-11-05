import SwiftUI

/// Rises a view into place after those before it in a sequence, or simply
/// shows it with Reduce Motion.
struct StaggeredReveal: ViewModifier {
    let index: Int
    let isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shown = self.isRevealed || self.reduceMotion
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : SpacingTokens.medium)
            .animation(self.reduceMotion ? nil : AnimationTokens.stagger(index: self.index), value: shown)
    }
}

extension View {
    func staggeredReveal(index: Int, isRevealed: Bool) -> some View {
        self.modifier(StaggeredReveal(index: index, isRevealed: isRevealed))
    }
}
