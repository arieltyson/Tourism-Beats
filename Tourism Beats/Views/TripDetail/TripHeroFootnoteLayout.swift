import SwiftUI

// MARK: - TripHeroFootnoteLayout

struct TripHeroFootnoteLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.small) {
                TripHeroFootnotePills(trip: self.trip)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripHeroFootnotePills(trip: self.trip)
            }
        }
    }
}
