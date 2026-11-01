import SwiftUI

// MARK: - RestaurantCountryPickerView

/// A searchable list of countries.
struct RestaurantCountryPickerView: View {
    @Binding var country: String
    let options: RestaurantPlaceOptions

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let countries = self.options.countries(matching: self.searchText)

        List(countries) { country in
            RestaurantFormOptionRow(
                title: country.name,
                flag: country.flag,
                isSelected: country.name.compare(
                    self.country,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            ) {
                self.country = country.name
                self.dismiss()
            }
        }
        .overlay {
            if countries.isEmpty {
                ContentUnavailableView.search(text: self.searchText)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Country")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: self.$searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search countries"
        )
        .searchFocused(self.$isSearchFocused)
        .onAppear {
            self.isSearchFocused = true
        }
    }
}
