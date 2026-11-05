import SwiftUI

// MARK: - TripSectionView

/// One status's trips: its title, then a card for each trip.
struct TripSectionView: View {
    let section: TripsViewModel.TripSection
    let viewModel: TripsViewModel
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        TripSectionHeader(status: self.section.status)
            .tripListRow(top: SpacingTokens.large)

        ForEach(self.section.trips) { trip in
            TripOverviewCard(
                trip: trip,
                cityModel: self.viewModel.cityModel(for: trip),
                countryFlag: self.viewModel.countryFlag(for: trip)
            )
            .background {
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    EmptyView()
                }
                // The card is the whole target; the list's chevron isn't wanted.
                .opacity(0)
            }
            .tripListRow()
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                // Not `.destructive`: the trip only goes once the alert is
                // confirmed, and that role would slide the card away first.
                Button("Delete", systemImage: "trash") {
                    self.onDeleteTrip(trip)
                }
                .tint(.red)
            }
        }
    }
}

// MARK: - TripSectionHeader

private struct TripSectionHeader: View {
    let status: TripStatus

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            Image(systemName: self.status.systemImage)
                .foregroundStyle(self.status.color)

            Text(self.status.label)
                .font(TypographyTokens.sectionHeader)
                .bold()
                .foregroundStyle(.primary)
        }
        // The cards below show how many there are; the header just names them.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Trip list rows

private extension View {
    /// A row with the screen's margins and nothing of the list's own look.
    func tripListRow(top: CGFloat = 0) -> some View {
        self
            .listRowInsets(EdgeInsets(
                top: top, leading: SpacingTokens.medium, bottom: 0, trailing: SpacingTokens.medium
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
