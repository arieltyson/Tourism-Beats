import SwiftUI

// MARK: - TripBudgetTypicalFooter

/// What a trip like this typically costs, with a way back to it.
///
/// The way back keeps its place while it isn't needed, fading rather than
/// folding away, so the sections below never shift as it comes and goes.
struct TripBudgetTypicalFooter: View {
    let typicalBudget: TripBudget
    let placeName: String
    let isTypical: Bool
    let onUseTypical: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text(self.summary)

            Button("Use Typical Budget", action: self.onUseTypical)
                .font(TypographyTokens.footnote.bold())
                .opacity(self.isTypical ? 0 : 1)
                .disabled(self.isTypical)
                .accessibilityHidden(self.isTypical)
        }
    }

    private var summary: String {
        let amount = self.typicalBudget.total.formatted(.budget(self.typicalBudget.currencyCode))
        return self.placeName.isEmpty
            ? "A trip like this typically costs about \(amount)."
            : "A trip like this to \(self.placeName) typically costs about \(amount)."
    }
}
