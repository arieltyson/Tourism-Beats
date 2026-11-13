import SwiftUI

// MARK: - TripBudgetFieldLabel

/// The budget row's content: its total, or marked optional until set.
struct TripBudgetFieldLabel: View {
    let budget: TripBudget?

    var body: some View {
        LabeledContent {
            if let budget {
                Text(budget.total, format: .budget(budget.currencyCode))
                    .monospacedDigit()
            } else {
                Text("Optional")
                    .foregroundStyle(.tertiary)
            }
        } label: {
            Label("Budget", systemImage: "creditcard")
        }
    }
}
