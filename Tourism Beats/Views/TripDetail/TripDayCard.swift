import SwiftUI

// MARK: - TripDayCard

struct TripDayCard: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                TripDayHeader(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities,
                    onDeleteDay: self.onDeleteDay
                )

                if self.day.sortedActivities.isEmpty {
                    TripEmptyDayContent(
                        onAddActivity: self.onAddActivity,
                        onSuggestActivities: self.onSuggestActivities
                    )
                } else {
                    VStack(spacing: SpacingTokens.small) {
                        ForEach(self.day.sortedActivities) { activity in
                            TripActivityRow(
                                activity: activity,
                                onEdit: {
                                    self.onEditActivity(activity)
                                },
                                onCycleStatus: {
                                    self.onCycleActivityStatus(activity)
                                },
                                onDelete: {
                                    self.onDeleteActivity(activity)
                                }
                            )
                        }
                    }

                    Button("Add Activity", systemImage: "plus") {
                        self.onAddActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.coral)
                }
            }
        }
    }
}
