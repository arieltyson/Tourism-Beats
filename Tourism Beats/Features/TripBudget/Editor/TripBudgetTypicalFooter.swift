import SwiftUI

// MARK: - TripBudgetTypicalFooter

/// What a trip like this typically costs, with a way back to it.
struct TripBudgetTypicalFooter: View {
    let typicalBudget: TripBudget
    let placeName: String
    let isTypical: Bool
    let onUseTypical: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text(self.summary)

            if !self.isTypical {
                Button("Use Typical Budget", action: self.onUseTypical)
                    .font(TypographyTokens.footnote.bold())
            }
        }
    }

    private var summary: String {
        let amount = self.typicalBudget.total.formatted(.budget(self.typicalBudget.currencyCode))
        return self.placeName.isEmpty
            ? "A trip like this typically costs about \(amount)."
            : "A trip like this to \(self.placeName) typically costs about \(amount)."
    }
}
