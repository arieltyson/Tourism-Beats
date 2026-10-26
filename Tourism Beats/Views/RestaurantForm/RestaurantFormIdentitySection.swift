import SwiftUI

// MARK: - RestaurantFormIdentitySection

/// The restaurant's name and where it is, with suggestions from cities already in the journal.
struct RestaurantFormIdentitySection: View {
    @Binding var name: String
    @Binding var city: String
    @Binding var country: String
    let existingCities: [String]

    @State private var showCitySuggestions = false

    var body: some View {
        Section("Restaurant") {
            TextField("Restaurant Name", text: self.$name)
                .textContentType(.organizationName)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                TextField("City", text: self.$city)
                    .textContentType(.addressCity)
                    .autocorrectionDisabled()
                    .onChange(of: self.city) { _, newValue in
                        let normalizedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.showCitySuggestions = !normalizedValue.isEmpty
                            && !self.matchingCities.isEmpty
                            && !self.matchingCities.contains(where: {
                                $0.caseInsensitiveCompare(normalizedValue) == .orderedSame
                            })
                    }

                if self.showCitySuggestions {
                    RestaurantFormCitySuggestions(
                        suggestions: Array(self.matchingCities.prefix(5)),
                        city: self.$city,
                        isPresented: self.$showCitySuggestions
                    )
                }
            }

            TextField("Country", text: self.$country)
                .textContentType(.countryName)
                .autocorrectionDisabled()
        }
    }

    private var matchingCities: [String] {
        self.existingCities.filter { $0.localizedStandardContains(self.city) }
    }
}
