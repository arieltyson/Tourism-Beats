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
        // A readable column, centred on a wide display such as iPhone Duo's
        // unfolded one; every phone is narrower than this.
        .frame(maxWidth: LayoutTokens.readableWidth)
        .frame(maxWidth: .infinity)
    }
}
