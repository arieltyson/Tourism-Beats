import SwiftUI

// MARK: - TripEmptyDayContent

/// The two ways to start an empty day: add an activity, or ask for ideas.
struct TripEmptyDayContent: View {
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.small) {
                TripEmptyDayActions(
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities
                )
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                TripEmptyDayActions(
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities
                )
            }
        }
    }
}

// MARK: - TripEmptyDayActions

private struct TripEmptyDayActions: View {
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?

    var body: some View {
        Button("Add Activity", systemImage: "plus") {
            self.onAddActivity()
        }
        .buttonStyle(.bordered)
        .tint(AppColors.coral)

        if let onSuggestActivities {
            Button("Suggest", systemImage: "sparkles") {
                onSuggestActivities()
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel("Suggest Activities")
            .accessibilityInputLabels(["Suggest", "Suggest Activities"])
        }
    }
}
