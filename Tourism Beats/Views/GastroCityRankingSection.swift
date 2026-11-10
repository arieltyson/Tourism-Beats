import SwiftUI

// MARK: - GastroCityRankingSection

/// The world's gastronomic capitals as a ranked list of slim banners, each
/// opening its city.
struct GastroCityRankingSection: View {
    let cities: [FeaturedGastroCity]

    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            GastroCityRankingHeader()

            LazyVGrid(columns: self.columns, spacing: SpacingTokens.small) {
                ForEach(self.cities.enumerated(), id: \.element.id) { index, gastroCity in
                    NavigationLink(value: gastroCity.city) {
                        GastroCityCard(gastroCity: gastroCity)
                    }
                    .buttonStyle(.cardPress)
                    .accessibilityHint("Opens \(gastroCity.city.name).")
                    .staggeredReveal(index: index, isRevealed: self.hasAppeared)
                }
            }
        }
        .onAppear { self.hasAppeared = true }
    }

    /// One column on a phone; side by side wherever banners fit.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: FoodJournalTokens.gastroCardMinimumWidth), spacing: SpacingTokens.small)]
    }
}

// MARK: - GastroCityRankingHeader

private struct GastroCityRankingHeader: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text("Top Gastro Cities")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                Text(GastroCityRanking.source)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: SpacingTokens.xSmall)

            GastroCityMethodologyButton()
        }
    }
}
