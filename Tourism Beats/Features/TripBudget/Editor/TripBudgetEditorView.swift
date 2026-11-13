import SwiftUI

// MARK: - TripBudgetEditorView

/// Sets how much a trip may cost and how that's split between its stay,
/// food, fun, and getting around.
///
/// Opening it starts from what such a trip typically costs, so there's
/// always a sensible budget to fine-tune rather than a blank to fill in.
struct TripBudgetEditorView: View {
    @Binding var budget: TripBudget?
    let typicalBudget: TripBudget
    let length: TripLength
    let placeName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: TripBudget

    init(
        budget: Binding<TripBudget?>,
        typicalBudget: TripBudget,
        length: TripLength,
        placeName: String
    ) {
        self._budget = budget
        self.typicalBudget = typicalBudget
        self.length = length
        self.placeName = placeName
        self._draft = State(initialValue: budget.wrappedValue ?? typicalBudget)
    }

    var body: some View {
        Form {
            Section {
                TripBudgetChart(budget: self.draft, length: self.length)
                    .listRowBackground(Color.clear)

                TripBudgetTotalField(budget: self.$draft)
            } footer: {
                TripBudgetTypicalFooter(
                    typicalBudget: self.typicalBudget,
                    placeName: self.placeName,
                    isTypical: self.draft == self.typicalBudget,
                    onUseTypical: { self.draft = self.typicalBudget }
                )
            }

            Section("Split") {
                ForEach(TripBudgetCategory.allCases) { category in
                    TripBudgetCategoryRow(category: category, budget: self.$draft, length: self.length)
                }
            }

            Section {
                Button("Remove Budget", role: .destructive) {
                    self.budget = nil
                    self.dismiss()
                }
            }
        }
        .keyboardDismissal()
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .animation(self.reduceMotion ? nil : AnimationTokens.standard, value: self.draft)
        .onAppear {
            // Opening the budget sets one; it can be removed from here.
            if self.budget == nil {
                self.budget = self.draft
            }
        }
        .onChange(of: self.draft) { _, draft in
            self.budget = draft
        }
    }
}
