import SwiftUI

// MARK: - FoodEmptyState

/// A new journal: one quiet pointer to the Add button, then the world's
/// best cuisines to spark the first entry.
struct FoodEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            FoodJournalStartHint()
            WorldCuisineRankingSection(cuisines: WorldCuisineRanking.top, source: WorldCuisineRanking.source)
        }
    }
}

// MARK: - FoodJournalStartHint

/// Points to the toolbar's Add button rather than repeating it.
private struct FoodJournalStartHint: View {
    var body: some View {
        Label {
            Text("Tap \(Image(systemName: "plus")) to save your first restaurant.")
        } icon: {
            Image(systemName: "fork.knife")
                .foregroundStyle(AppColors.coral)
        }
        .font(TypographyTokens.cardLabel)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Use Add Restaurant to save your first restaurant.")
    }
}
