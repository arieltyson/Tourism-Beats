import SwiftUI

// MARK: - TripBasicsSection

struct TripBasicsSection: View {
    @Binding var name: String
    @Binding var city: String
    let countryDisplayLabel: String
    let hasCountryValue: Bool
    let onSelectCountry: () -> Void

    var body: some View {
        Section {
            TextField("Trip Name", text: self.$name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TripCountryPickerField(
                countryDisplayLabel: self.countryDisplayLabel,
                hasCountryValue: self.hasCountryValue,
                onSelectCountry: self.onSelectCountry
            )

            TextField("City", text: self.$city)
                .textContentType(.addressCity)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        } header: {
            Text("Trip Details")
        } footer: {
            Text(
                "Only the trip name and city are required. Dates, notes, and activities can stay flexible."
            )
        }
    }
}
