import SwiftUI

// MARK: - TripBudgetCategoryRow

/// One category's share of the budget, set with a slider.
///
/// Setting it locks it, shown by a small lock beside its amount; only the
/// unlocked categories rebalance, so the total holds and nothing set moves on
/// its own. The slider stops, with a firm tap, where the locked ones leave
/// no room, and tapping the lock lets the category rebalance again.
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
                .accessibilityHidden(true)

                Spacer(minLength: SpacingTokens.small)

                if self.budget.isLocked(self.category) {
                    TripBudgetLockButton(category: self.category) {
                        self.budget.unlock(self.category)
                    }
                }

                Text(self.amount, format: self.format)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: self.amount))
                    .accessibilityHidden(true)
            }

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
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: self.budget.isHeldBack(self.category)) { _, isHeldBack in
                isHeldBack
            }
            .accessibilityValue(self.accessibilityValue)
            .accessibilityHint("Locks it at the amount you choose. Unlocked categories make room.")

            Text(self.rateLabel)
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, SpacingTokens.xxSmall)
    }

    /// The amount, and whether it's locked.
    private var accessibilityValue: String {
        let amount = self.amount.formatted(self.format)
        return self.budget.isLocked(self.category) ? "\(amount), locked" : amount
    }

    /// The amount for each night or day, such as "About $150 a night".
    private var rateLabel: String {
        let rate = self.budget.amount(for: self.category, per: self.length).formatted(self.format)
        return self.category.isNightly ? "About \(rate) a night" : "About \(rate) a day"
    }
}
