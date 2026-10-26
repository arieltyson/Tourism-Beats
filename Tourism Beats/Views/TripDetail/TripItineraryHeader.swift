import SwiftUI

// MARK: - TripItineraryHeader

struct TripItineraryHeader: View {
    let onAddDay: () -> Void
    let onSuggest: (() -> Void)?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                Spacer(minLength: SpacingTokens.small)

                self.actions
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                HStack(spacing: SpacingTokens.small) {
                    self.actions
                }
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                self.actions
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if let onSuggest {
            Button("Suggest", systemImage: "sparkles") {
                onSuggest()
            }
            .buttonStyle(.bordered)
            .tint(AppColors.gold)
            .accessibilityLabel("Suggest Activities")
            .accessibilityInputLabels(["Suggest", "Suggest Activities", "Suggest a Plan"])
        }

        Button("Add Day", systemImage: "plus") {
            self.onAddDay()
        }
        .buttonStyle(.bordered)
        .tint(AppColors.coral)
    }
}
