import SwiftUI

// MARK: - TripDayHeaderAccessoryContent

struct TripDayHeaderAccessoryContent: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?
    let onDeleteDay: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                TripDayHeaderCounts(day: self.day)
                TripDayHeaderMenu(
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities,
                    onDeleteDay: self.onDeleteDay
                )
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripDayHeaderCounts(day: self.day)
                TripDayHeaderMenu(
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities,
                    onDeleteDay: self.onDeleteDay
                )
            }
        }
    }
}
