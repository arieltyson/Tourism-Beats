import SwiftUI

// MARK: - TripHeroBadgeLayout

struct TripHeroBadgeLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                TripHeroStatusBadges(trip: self.trip)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripHeroStatusBadges(trip: self.trip)
            }
        }
    }
}
