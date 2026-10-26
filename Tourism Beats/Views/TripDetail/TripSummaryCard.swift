import SwiftUI

// MARK: - TripSummaryCard

struct TripSummaryCard: View {
    let trip: Trip

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Text("Trip Snapshot")
                    .font(TypographyTokens.sectionHeader)
                    .bold()

                TripSummaryMetricsLayout(trip: self.trip)
            }
        }
    }
}
