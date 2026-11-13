import SwiftUI

// MARK: - TripBudgetSection

/// The trip's optional budget, which opens to be fine-tuned.
struct TripBudgetSection: View {
    let budget: TripBudget?

    var body: some View {
        Section {
            NavigationLink(value: TripBudgetRoute()) {
                TripBudgetFieldLabel(budget: self.budget)
            }
        } footer: {
            if self.budget == nil {
                Text("Split what you'd like to spend, and get hotel picks that fit it.")
            }
        }
    }
}
