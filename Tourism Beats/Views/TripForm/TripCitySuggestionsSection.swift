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
                                .foregroundStyle(.primary)

                            Text("\(city.country.flag) \(city.country.name)")
                                .font(TypographyTokens.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .foregroundStyle(AppColors.coral)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Suggested Cities")
        }
    }
}
