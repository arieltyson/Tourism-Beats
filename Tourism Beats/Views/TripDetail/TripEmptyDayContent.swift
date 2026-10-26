import SwiftUI

// MARK: - TripEmptyDayContent

struct TripEmptyDayContent: View {
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text("No activities yet")
                .font(TypographyTokens.cardLabel)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: SpacingTokens.small) {
                    self.actions
                }

                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    self.actions
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if let onSuggestActivities {
            Button("Suggest Activities", systemImage: "sparkles") {
                onSuggestActivities()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.coral)

            Button("Add First Activity", systemImage: "plus") {
                self.onAddActivity()
            }
            .buttonStyle(.bordered)
            .tint(AppColors.coral)
        } else {
            Button("Add First Activity", systemImage: "plus") {
                self.onAddActivity()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.coral)
        }
    }
}
