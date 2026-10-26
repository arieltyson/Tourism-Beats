import SwiftUI

// MARK: - TripDayHeader

struct TripDayHeader: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?
    let onDeleteDay: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                TripDayHeaderTitle(day: self.day)

                Spacer(minLength: SpacingTokens.small)

                TripDayHeaderAccessoryContent(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities,
                    onDeleteDay: self.onDeleteDay
                )
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                TripDayHeaderTitle(day: self.day)

                TripDayHeaderAccessoryContent(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onSuggestActivities: self.onSuggestActivities,
                    onDeleteDay: self.onDeleteDay
                )
            }
        }
    }
}
