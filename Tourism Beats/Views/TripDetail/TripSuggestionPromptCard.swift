import SwiftUI

// MARK: - TripSuggestionPromptCard

/// Offers a suggested plan when a trip has no activities yet.
struct TripSuggestionPromptCard: View {
    let trip: Trip
    let onSuggest: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Label("Start With a Suggested Plan", systemImage: "sparkles")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.gold)

                Text(self.message)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)

                Button("Suggest a Plan", systemImage: "sparkles") {
                    self.onSuggest()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.coral)
            }
        }
    }

    private var message: String {
        let dayLabel = self.trip.dayCount == 1
            ? "your day"
            : "all \(self.trip.dayCount.formatted(.number)) days"
        return "Fill \(dayLabel) with top sights and restaurants in \(self.trip.city), "
            + "grouped by area. You review everything before it's added."
    }
}
