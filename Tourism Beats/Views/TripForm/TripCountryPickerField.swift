import SwiftUI

// MARK: - TripCountryPickerField

struct TripCountryPickerField: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool
    let onSelectCountry: () -> Void

    var body: some View {
        Button(action: self.onSelectCountry) {
            ViewThatFits(in: .horizontal) {
                TripCountryPickerFieldInlineContent(
                    countryDisplayLabel: self.countryDisplayLabel,
                    hasCountryValue: self.hasCountryValue
                )

                TripCountryPickerFieldStackedContent(
                    countryDisplayLabel: self.countryDisplayLabel,
                    hasCountryValue: self.hasCountryValue
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            self.hasCountryValue
                ? "Country, \(self.countryDisplayLabel)"
                : "Country, Choose a country"
        )
        .accessibilityHint("Opens the list of countries")
        .accessibilityInputLabels(["Country", "Choose Country"])
    }
}
