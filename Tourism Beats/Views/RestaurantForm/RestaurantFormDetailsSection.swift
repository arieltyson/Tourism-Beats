import SwiftUI

// MARK: - RestaurantFormDetailsSection

/// Cuisine and the dish worth ordering.
struct RestaurantFormDetailsSection: View {
    @Binding var cuisine: RestaurantCuisine?
    @Binding var bestDish: String

    var body: some View {
        Section("Details") {
            Picker("Cuisine", selection: self.$cuisine) {
                Text("None")
                    .tag(nil as RestaurantCuisine?)

                ForEach(RestaurantCuisine.allCases) { cuisine in
                    Text(cuisine.label)
                        .tag(cuisine as RestaurantCuisine?)
                }
            }

            TextField("Best Dish (optional)", text: self.$bestDish)
        }
    }
}
