import SwiftUI

// MARK: - TripBudgetLockButton

/// A category's lock, at the end of its row. Locked, the category stays where
/// it is while the others move; tapping turns the lock either way.
struct TripBudgetLockButton: View {
    let category: TripBudgetCategory
    let isLocked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(
            "Lock \(self.category.label)",
            systemImage: self.isLocked ? "lock.fill" : "lock.open",
            action: self.onToggle
        )
        .labelStyle(.iconOnly)
        .foregroundStyle(self.isLocked ? self.category.color : Color.secondary)
        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer)))
        .buttonStyle(.borderless)
        // The glyph stays small; the tap area reaches past it.
        .contentShape(.rect.inset(by: -SpacingTokens.small))
        .sensoryFeedback(.selection, trigger: self.isLocked)
        .accessibilityAddTraits(self.isLocked ? [.isToggle, .isSelected] : .isToggle)
        .accessibilityHint("A locked category stays put while the others move")
    }
}
