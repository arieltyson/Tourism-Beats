import SwiftUI

// MARK: - TripBudgetCategoryRow

/// One category's share of the budget, set with a slider. Moving it
/// rebalances the other categories, so the total holds.
struct TripBudgetCategoryRow: View {
    let category: TripBudgetCategory
    @Binding var budget: TripBudget
    let length: TripLength

    private var amount: Double {
        self.budget.amount(for: self.category)
    }

    private var format: FloatingPointFormatStyle<Double>.Currency {
        .budget(self.budget.currencyCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            HStack(spacing: SpacingTokens.small) {
                Label {
                    Text(self.category.label)
                } icon: {
                    Image(systemName: self.category.systemImage)
                        .foregroundStyle(self.category.color)
                }

                Spacer(minLength: SpacingTokens.small)

                Text(self.amount, format: self.format)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: self.amount))
            }
            .accessibilityHidden(true)

            Slider(
                value: Binding(
                    get: { self.amount },
                    set: { self.budget.setAmount($0, for: self.category) }
                ),
                in: 0 ... max(self.budget.total, 1)
            ) {
                Text(self.category.label)
            }
            .tint(self.category.color)
            .accessibilityValue(Text(self.amount, format: self.format))
            .accessibilityHint("Adjusting it rebalances the other categories")

            Text(self.rateLabel)
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, SpacingTokens.xxSmall)
    }

    /// The amount for each night or day, such as "About $150 a night".
    private var rateLabel: String {
        let rate = self.budget.amount(for: self.category, per: self.length).formatted(self.format)
        return self.category.isNightly ? "About \(rate) a night" : "About \(rate) a day"
    }
}
