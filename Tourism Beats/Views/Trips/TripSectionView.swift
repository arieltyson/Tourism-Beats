import SwiftUI

// MARK: - TripSectionView

struct TripSectionView: View {
    let section: TripsViewModel.TripSection
    let viewModel: TripsViewModel
    let onEditTrip: (Trip) -> Void
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

                Spacer()

                Text(self.section.trips.count, format: .number)
                    .font(TypographyTokens.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

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

                    Button("Edit", systemImage: "pencil") {
                        self.onEditTrip(trip)
                    }
                    .tint(AppColors.info)
                }
            }
        }
    }
}
