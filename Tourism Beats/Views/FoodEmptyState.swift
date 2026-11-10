import SwiftUI

// MARK: - FoodEmptyState

/// A new journal: one quiet pointer to the Add button, then the world's
/// gastronomic capitals to spark the first entry.
struct FoodEmptyState: View {
    let gastroCities: [FeaturedGastroCity]

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            FoodJournalStartHint()
            GastroCityRankingSection(cities: self.gastroCities)
        }
    }
}

// MARK: - FoodJournalStartHint

/// Says what the journal is for and points to the toolbar's Add button
/// rather than repeating it.
private struct FoodJournalStartHint: View {
    var body: some View {
        GlassCard(cornerRadius: FoodJournalTokens.gastroCardCornerRadius) {
            HStack(spacing: SpacingTokens.small) {
                Image(systemName: "fork.knife")
                    .font(TypographyTokens.sectionHeader)
                    .foregroundStyle(AppColors.coral)
                    .frame(minWidth: SpacingTokens.minimumTapTarget, minHeight: SpacingTokens.minimumTapTarget)
                    .background(AppColors.coral.opacity(0.15), in: .circle)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Your journal starts here")
                        .font(TypographyTokens.sectionHeader)
                    Text("Tap \(Image(systemName: "plus")) to save a favourite meal.")
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your journal starts here. Use Add Restaurant to save a favourite meal.")
    }
}
