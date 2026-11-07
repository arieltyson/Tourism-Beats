import SwiftUI

// MARK: - BucketListPlacePicker

/// Every country, and as soon as a search starts, the app's cities too, so a
/// place can be found by its own name without knowing its country.
struct BucketListPlacePicker: View {
    let form: BucketListFormViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        let cities = self.form.anyCities(matching: self.searchText)
        let countries = self.form.countries(matching: self.searchText)

        NavigationStack {
            List {
                if !cities.isEmpty {
                    Section("Cities") {
                        ForEach(cities) { city in
                            BucketListCityPickerRow(
                                title: "\(city.country.flag) \(city.name)",
                                detail: city.locationName,
                                isSelected: self.form.city == city
                            ) {
                                self.form.selectCity(city)
                                self.dismiss()
                            }
                            .accessibilityLabel("\(city.name), \(city.locationName)")
                        }
                    }
                }

                Section(cities.isEmpty ? "" : "Countries") {
                    ForEach(countries) { country in
                        BucketListCityPickerRow(
                            title: "\(country.flag) \(country.name)",
                            detail: nil,
                            isSelected: self.form.city == nil && self.form.countryCode == country.code
                        ) {
                            self.form.selectCountry(code: country.code)
                            self.dismiss()
                        }
                        .accessibilityLabel(country.name)
                    }
                }
            }
            .overlay {
                if cities.isEmpty, countries.isEmpty {
                    ContentUnavailableView.search(text: self.searchText)
                }
            }
            .searchable(
                text: self.$searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Country or city"
            )
            .navigationTitle("Choose a Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        self.dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
