import SwiftUI

// MARK: - TripDetailContent

struct TripDetailContent: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String
    let onAddDay: () -> Void
    let onSuggest: ((TripSuggestionsViewModel.Scope) -> Void)?
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
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

            if self.trip.activityCount == 0, let onSuggest {
                TripSuggestionPromptCard(trip: self.trip) {
                    onSuggest(.trip)
                }
            }

            TripItinerarySection(
                trip: self.trip,
                onAddDay: self.onAddDay,
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
