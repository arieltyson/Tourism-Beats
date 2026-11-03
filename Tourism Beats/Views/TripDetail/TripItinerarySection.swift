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

    /// The header and each day are separate children of the lazy stack
    /// around this view, so days are built only as they scroll into view.
    var body: some View {
        // Sorted once per update rather than once per day.
        let days = self.trip.sortedDays

        Text("Itinerary")
            .font(TypographyTokens.songTitle)
            .bold()
            .accessibilityAddTraits(.isHeader)
            // The gap above the itinerary matches the one between cards.
            .padding(.top, SpacingTokens.large - SpacingTokens.medium)

        ForEach(days) { day in
            TripDayCard(
                day: day,
                canDelete: days.count > 1,
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
}
