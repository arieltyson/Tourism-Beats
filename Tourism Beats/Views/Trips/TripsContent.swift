import SwiftUI

// MARK: - TripsContent

/// The trips, grouped by status, as cards in a list styled to disappear:
/// no row backgrounds or separators, only the cards themselves.
struct TripsContent: View {
    let sections: [TripsViewModel.TripSection]
    let viewModel: TripsViewModel
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        List {
            ForEach(self.sections) { section in
                TripSectionView(
                    section: section,
                    viewModel: self.viewModel,
                    onDeleteTrip: self.onDeleteTrip
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listRowSpacing(SpacingTokens.small)
    }
}
