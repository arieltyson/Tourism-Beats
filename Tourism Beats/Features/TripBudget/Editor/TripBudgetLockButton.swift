import SwiftUI

// MARK: - TripBudgetLockButton

/// The lock on a category the traveller has set. Tapping it unlocks the
/// category so it rebalances with the others again.
struct TripBudgetLockButton: View {
    let category: TripBudgetCategory
    let onUnlock: () -> Void

    var body: some View {
        Button("Unlock \(self.category.label)", systemImage: "lock.fill", action: self.onUnlock)
            .labelStyle(.iconOnly)
            .font(TypographyTokens.caption)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            // The glyph stays small; the tap area reaches past it.
            .contentShape(.rect.inset(by: -SpacingTokens.small))
            .transition(.scale.combined(with: .opacity))
            .accessibilityHint("Lets it rebalance with the other categories")
    }
}
