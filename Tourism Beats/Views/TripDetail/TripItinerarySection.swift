import SwiftUI

// MARK: - TripItinerarySection

struct TripItinerarySection: View {
    let trip: Trip
    let onSuggest: ((TripSuggestionsViewModel.Scope) -> Void)?
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text("Itinerary")
                .font(TypographyTokens.songTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)

            ForEach(self.trip.sortedDays) { day in
                TripDayCard(
                    day: day,
                    canDelete: self.trip.sortedDays.count > 1,
                    onAddActivity: {
                        self.onAddActivity(day)
                    },
                    onSuggestActivities: self.onSuggest.map { onSuggest in
                        { onSuggest(.day(day)) }
                    },
                    onEditActivity: self.onEditActivity,
                    onCycleActivityStatus: self.onCycleActivityStatus,
                    onDeleteActivity: self.onDeleteActivity,
                    onDeleteDay: {
                        self.onDeleteDay(day)
                    }
                )
                .id(day.persistentModelID)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
