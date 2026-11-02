import SwiftUI

// MARK: - TripCitySuggestionsSection

struct TripCitySuggestionsSection: View {
    let suggestions: [CityModel]
    let onSelectCity: (CityModel) -> Void

    var body: some View {
        Section {
            ForEach(self.suggestions) { city in
                Button {
                    self.onSelectCity(city)
                } label: {
                    HStack(spacing: SpacingTokens.small) {
                        VStack(
                            alignment: .leading,
                            spacing: SpacingTokens.xxSmall
                        ) {
                            Text(city.name)
                                .foregroundStyle(Color.primary)

                            Text("\(city.country.flag) \(city.country.name)")
                                .font(TypographyTokens.caption)
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .foregroundStyle(AppColors.coral)
                            .accessibilityHidden(true)
                    }
                    // The whole row is the target, not only its text and arrow.
                    .contentShape(.rect)
                }
                .accessibilityLabel("\(city.name), \(city.country.name)")
                .accessibilityHint("Uses this city for the trip")
            }
        } header: {
            Text("Suggested Cities")
        }
    }
}
