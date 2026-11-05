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
                    // Not `.destructive`: that role tells the system the row is
                    // going away, so it stays slid open while the deletion is
                    // confirmed, and stranded if it's cancelled. Tinted red, the
                    // swipe closes and the card settles before the alert asks.
                    Button("Delete", systemImage: "trash") {
                        self.onDeleteTrip(trip)
                    }
                    .tint(.red)
                }
            }
        }
    }
}
