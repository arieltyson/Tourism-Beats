import SwiftUI

// MARK: - BucketListPlaceFields

/// The place to visit, as rows of the form's one question section.
///
/// It starts as a single search for a country or a city. Once a country is
/// chosen, it shows, with an optional city in it beneath; choosing a city
/// fills in both. The city can be let go from its own list, under Any City.
struct BucketListPlaceFields: View {
    @Bindable var form: BucketListFormViewModel
    let onChooseCountry: () -> Void

    var body: some View {
        Group {
            Button(action: self.onChooseCountry) {
                if let country = self.form.country {
                    LabeledContent("Country") {
                        Text("\(country.flag) \(country.name)")
                            .foregroundStyle(.primary)
                    }
                } else {
                    Label("Search by country or city", systemImage: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .contentShape(.rect)
            .accessibilityHint("Finds a country, or a city and its country")

            if self.form.hasCities {
                NavigationLink {
                    BucketListCityPicker(form: self.form)
                } label: {
                    LabeledContent("City") {
                        Text(self.form.city?.name ?? "Optional")
                            .foregroundStyle(self.form.city == nil ? .secondary : .primary)
                    }
                }
                .accessibilityHint("Lists the cities in this country")
                .transition(.opacity)
            }
        }
    }
}
