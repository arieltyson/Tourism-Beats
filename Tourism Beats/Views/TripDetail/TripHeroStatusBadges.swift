import SwiftUI

// MARK: - TripHeroStatusBadges

struct TripHeroStatusBadges: View {
    let trip: Trip

    var body: some View {
        Group {
            TripsBadge(
                title: self.trip.status.label,
                systemImage: self.trip.status.systemImage,
                tint: self.trip.status.color
            )

            if self.trip.isSample {
                TripsBadge(
                    title: "Sample itinerary",
                    systemImage: "sparkles",
                    tint: AppColors.gold
                )
            }
        }
    }
}
