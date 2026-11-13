import SwiftUI

// MARK: - TripBudgetTotalField

/// The budget's total, typed in. The split between categories holds.
struct TripBudgetTotalField: View {
    @Binding var budget: TripBudget

    var body: some View {
        LabeledContent("Total") {
            TextField(
                "Total",
                value: Binding(
                    get: { self.budget.total },
                    set: { self.budget.setTotal($0) }
                ),
                format: .budget(self.budget.currencyCode)
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
        }
    }
}
