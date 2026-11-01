import SwiftUI

// MARK: - RestaurantCityPickerView

/// A searchable list of cities. Choosing one also fills in its country, and
/// any city can be used by typing its name.
struct RestaurantCityPickerView: View {
    @Binding var city: String
    @Binding var country: String
    let options: RestaurantPlaceOptions

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let trimmedQuery = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let results = self.options.places(matching: trimmedQuery)
        let hasExactMatch = results.contains {
            $0.city.compare(trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }

        List {
            if trimmedQuery.isEmpty {
                if !self.options.journalPlaces.isEmpty {
                    Section("In Your Journal") {
                        RestaurantCityPickerRows(
                            places: self.options.journalPlaces,
                            selectedIdentifier: self.selectedIdentifier,
                            onSelect: self.select
                        )
                    }
                }

                Section("All Cities") {
                    RestaurantCityPickerRows(
                        places: self.options.catalogPlaces,
                        selectedIdentifier: self.selectedIdentifier,
                        onSelect: self.select
                    )
                }
            } else {
                if !hasExactMatch {
                    Button("Use “\(trimmedQuery)”", systemImage: "plus.circle.fill") {
                        self.city = trimmedQuery
                        self.dismiss()
                    }
                }

                RestaurantCityPickerRows(
                    places: results,
                    selectedIdentifier: self.selectedIdentifier,
                    onSelect: self.select
                )
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("City")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: self.$searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search or enter a city"
        )
        .searchFocused(self.$isSearchFocused)
        .onAppear {
            self.isSearchFocused = true
        }
    }

    private var selectedIdentifier: String {
        RestaurantPlace(city: self.city, country: self.country).id
    }

    private func select(_ place: RestaurantPlace) {
        self.city = place.city
        if !place.country.isEmpty {
            self.country = place.country
        }
        self.dismiss()
    }
}

// MARK: - RestaurantCityPickerRows

/// City rows, each showing its country beneath it.
private struct RestaurantCityPickerRows: View {
    let places: [RestaurantPlace]
    let selectedIdentifier: String
    let onSelect: (RestaurantPlace) -> Void

    var body: some View {
        ForEach(self.places) { place in
            RestaurantFormOptionRow(
                title: place.city,
                subtitle: place.country.isEmpty ? nil : place.country,
                flag: place.flag,
                isSelected: place.id == self.selectedIdentifier
            ) {
                self.onSelect(place)
            }
        }
    }
}
