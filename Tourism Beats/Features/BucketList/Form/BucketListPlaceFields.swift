import SwiftUI

// MARK: - BucketListPlaceFields

/// The country to visit and, if one comes to mind, a city in it, as rows
/// of the form's one question section.
struct BucketListPlaceFields: View {
    @Bindable var form: BucketListFormViewModel
    let onChooseCountry: () -> Void

    var body: some View {
        Group {
            Button(action: self.onChooseCountry) {
                LabeledContent("Country") {
                    if let country = self.form.country {
                        Text("\(country.flag) \(country.name)")
                            .foregroundStyle(.primary)
                    } else {
                        Text("Choose")
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Finds a country, or a city and its country")

            NavigationLink {
                BucketListCityPicker(form: self.form)
            } label: {
                LabeledContent("City") {
                    Text(self.form.city?.name ?? "Optional")
                        .foregroundStyle(self.form.city == nil ? .secondary : .primary)
                }
            }
            .disabled(!self.form.hasCities)
            .accessibilityHint(self.form.country == nil ? "Choose a country first" : "Lists the cities in this country")
        }
    }
}
