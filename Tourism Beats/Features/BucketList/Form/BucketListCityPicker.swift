import SwiftUI

// MARK: - BucketListCityPicker

/// The app's cities in the chosen country, to pick one quickly or none.
struct BucketListCityPicker: View {
    @Bindable var form: BucketListFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        List {
            if self.searchText.isEmpty {
                BucketListCityPickerRow(title: "Any City", detail: nil, isSelected: self.form.city == nil) {
                    self.choose(nil)
                }
            }

            ForEach(self.form.cities(matching: self.searchText)) { city in
                BucketListCityPickerRow(
                    title: city.name,
                    detail: city.administrativeArea,
                    isSelected: self.form.city == city
                ) {
                    self.choose(city)
                }
            }
        }
        .searchable(text: self.$searchText, prompt: "Search cities")
        .navigationTitle(self.form.country?.name ?? "City")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choose(_ city: CityModel?) {
        self.form.city = city
        self.dismiss()
    }
}
