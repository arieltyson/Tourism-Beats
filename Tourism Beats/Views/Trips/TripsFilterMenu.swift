import SwiftUI

// MARK: - TripsFilterMenu

struct TripsFilterMenu: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedFilter: TripStatus?

    var body: some View {
        Menu {
            Button("All", systemImage: self.selectedFilter == nil ? "checkmark" : "line.3.horizontal.decrease.circle") {
                self.selectedFilter = nil
            }

            ForEach(TripStatus.allCases) { status in
                Button(
                    status.label,
                    systemImage: self.selectedFilter == status ? "checkmark" : status.systemImage
                ) {
                    self.selectedFilter = status
                }
            }
        } label: {
            if self.reduceMotion {
                Image(
                    systemName: self.selectedFilter == nil
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
            } else {
                Image(
                    systemName: self.selectedFilter == nil
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
                .symbolEffect(.bounce, value: self.selectedFilter)
            }
        }
        .accessibilityLabel("Filter trips")
        .accessibilityInputLabels(["Filter Trips", "Trip Filter"])
    }
}
