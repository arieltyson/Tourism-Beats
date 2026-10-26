import SwiftUI

// MARK: - TripsContent

struct TripsContent: View {
    let sections: [TripsViewModel.TripSection]
    let viewModel: TripsViewModel
    let onEditTrip: (Trip) -> Void
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: SpacingTokens.large) {
            ForEach(self.sections) { section in
                TripSectionView(
                    section: section,
                    viewModel: self.viewModel,
                    onEditTrip: self.onEditTrip,
                    onDeleteTrip: self.onDeleteTrip
                )
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
    }
}
