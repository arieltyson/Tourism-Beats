import SwiftUI

// MARK: - RestaurantFormDetailsSection

/// Cuisine and the dish worth ordering.
struct RestaurantFormDetailsSection: View {
    let cuisine: RestaurantCuisine?
    @Binding var bestDish: String
    var focusedField: FocusState<RestaurantFormField?>.Binding

    var body: some View {
        Section("Details") {
            RestaurantFormChoiceLink(
                title: "Cuisine",
                value: self.cuisine?.label ?? "None",
                route: .cuisine
            )

            TextField("Best Dish (optional)", text: self.$bestDish)
                .focused(self.focusedField, equals: .bestDish)
                .submitLabel(.done)
        }
    }
}
