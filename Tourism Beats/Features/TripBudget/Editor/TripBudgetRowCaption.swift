import SwiftUI

// MARK: - TripBudgetRowCaption

/// The line under a category's slider: its nightly or daily amount, or, in
/// red, how far the budget runs over.
struct TripBudgetRowCaption: View {
    let text: String
    let isOverBudget: Bool

    var body: some View {
        Text(self.text)
            .font(TypographyTokens.caption)
            .foregroundStyle(self.isOverBudget ? AppColors.danger : .secondary)
            .contentTransition(.opacity)
            // VoiceOver hears this in the slider's value.
            .accessibilityHidden(true)
    }
}
