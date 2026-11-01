import SwiftUI

// MARK: - RestaurantCuisinePickerView

/// A searchable list of cuisines, grouped into drinks, sweets, dining, and world cuisines.
struct RestaurantCuisinePickerView: View {
    @Binding var cuisine: RestaurantCuisine?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        let sections = RestaurantCuisineSection.sections(matching: self.searchText)

        List {
            if self.searchText.isEmpty {
                RestaurantFormOptionRow(title: "None", isSelected: self.cuisine == nil) {
                    self.select(nil)
                }
            }

            ForEach(sections) { section in
                Section(section.category.title) {
                    ForEach(section.cuisines) { cuisine in
                        RestaurantFormOptionRow(
                            title: cuisine.label,
                            isSelected: self.cuisine == cuisine
                        ) {
                            self.select(cuisine)
                        }
                    }
                }
            }
        }
        .overlay {
            if sections.isEmpty {
                ContentUnavailableView.search(text: self.searchText)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Cuisine")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: self.$searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search cuisines"
        )
    }

    private func select(_ cuisine: RestaurantCuisine?) {
        self.cuisine = cuisine
        self.dismiss()
    }
}
