import SwiftUI

// MARK: - TripHeroFootnotePills

struct TripHeroFootnotePills: View {
    let trip: Trip

    var body: some View {
        Group {
            TripsFootnotePill(
                title: self.trip.scheduleSummaryLabel,
                systemImage: "list.bullet.rectangle.portrait"
            )

            if let progressLabel = self.trip.progressLabel {
                TripsFootnotePill(
                    title: progressLabel,
                    systemImage: "checkmark.circle"
                )
            }
        }
    }
}
