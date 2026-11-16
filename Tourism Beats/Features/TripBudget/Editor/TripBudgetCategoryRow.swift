import SwiftUI

// MARK: - TripBudgetCategoryRow

/// One category's share of the budget, set with a slider, with its lock as the
/// last thing on the row.
///
/// Moving the slider rebalances the unlocked categories; a locked one stays
/// exactly where it is until it's unlocked. When the unlocked categories have
/// nothing left to give, the category runs over the budget instead, and the
/// row turns red and says by how much.
struct TripBudgetCategoryRow: View {
    let category: TripBudgetCategory
    @Binding var budget: TripBudget
    let length: TripLength

    private var amount: Double {
        self.budget.amount(for: self.category)
    }

    private var isLocked: Bool {
        self.budget.isLocked(self.category)
    }

    private var isOverBudget: Bool {
        self.budget.isOverBudget(self.category)
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

                Text(self.amount, format: self.format)
                    .monospacedDigit()
                    .foregroundStyle(self.isOverBudget ? AppColors.danger : .primary)
                    .contentTransition(.numericText(value: self.amount))
                    .accessibilityHidden(true)

                TripBudgetLockButton(category: self.category, isLocked: self.isLocked) {
                    self.budget.toggleLock(self.category)
                }
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
            .tint(self.isOverBudget ? AppColors.danger : self.category.color)
            .disabled(self.isLocked)
            .sensoryFeedback(.warning, trigger: self.isOverBudget) { _, isOverBudget in
                isOverBudget
            }
            .accessibilityValue(self.accessibilityValue)
            .accessibilityHint(self.isLocked ? "Unlock it to change it" : "Adjusting it rebalances the unlocked categories")

            TripBudgetRowCaption(
                text: self.caption,
                isOverBudget: self.isOverBudget
            )
        }
        .padding(.vertical, SpacingTokens.xxSmall)
    }

    /// How far the budget runs over, or the amount for each night or day,
    /// such as "About $150 a night".
    private var caption: String {
        if self.isOverBudget {
            return "Exceeds budget by \(self.budget.overage.formatted(self.format))"
        }
        let rate = self.budget.amount(for: self.category, per: self.length).formatted(self.format)
        return self.category.isNightly ? "About \(rate) a night" : "About \(rate) a day"
    }

    /// The amount, and whether it's locked or over the budget.
    private var accessibilityValue: String {
        var parts = [self.amount.formatted(self.format)]
        if self.isLocked { parts.append("locked") }
        if self.isOverBudget { parts.append("exceeds budget by \(self.budget.overage.formatted(self.format))") }
        return parts.formatted(.list(type: .and, width: .narrow))
    }
}
