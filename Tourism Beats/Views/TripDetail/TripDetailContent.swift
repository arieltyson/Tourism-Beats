import SwiftUI

// MARK: - TripDetailContent

struct TripDetailContent: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String
    let onSuggest: ((TripSuggestionsViewModel.Scope) -> Void)?
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
        // Lazy, so a long itinerary builds only the days on screen and the
        // trip opens without laying out every activity first.
        LazyVStack(alignment: .leading, spacing: SpacingTokens.medium) {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                TripHeroCard(
                    trip: self.trip,
                    cityModel: self.cityModel,
                    countryFlag: self.countryFlag
                )

                if self.trip.isSample {
                    TripSampleNoticeCard(trip: self.trip)
                }

                TripSummaryCard(trip: self.trip)

                if let notes = self.trip.notesSummary {
                    TripNotesCard(notes: notes)
                }
            }

            TripItinerarySection(
                trip: self.trip,
                onSuggest: self.onSuggest,
                onAddActivity: self.onAddActivity,
                onEditActivity: self.onEditActivity,
                onCycleActivityStatus: self.onCycleActivityStatus,
                onDeleteActivity: self.onDeleteActivity,
                onDeleteDay: self.onDeleteDay
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
