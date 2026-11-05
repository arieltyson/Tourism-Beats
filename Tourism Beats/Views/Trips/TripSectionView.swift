import SwiftUI

// MARK: - TripSectionView

struct TripSectionView: View {
    let section: TripsViewModel.TripSection
    let viewModel: TripsViewModel
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            HStack(spacing: SpacingTokens.xSmall) {
                Image(systemName: self.section.status.systemImage)
                    .foregroundStyle(self.section.status.color)

                Text(self.section.status.label)
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(.primary)
            }
            // The cards below show how many there are; the header just names them.
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ForEach(self.section.trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    TripOverviewCard(
                        trip: trip,
                        cityModel: self.viewModel.cityModel(for: trip),
                        countryFlag: self.viewModel.countryFlag(for: trip)
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        self.onDeleteTrip(trip)
                    }
                }
            }
        }
    }
}
