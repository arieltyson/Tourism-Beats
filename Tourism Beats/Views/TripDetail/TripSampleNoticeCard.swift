import SwiftUI

// MARK: - TripSampleNoticeCard

/// Explains that a sample trip is an example, not a recommended trip length.
struct TripSampleNoticeCard: View {
    let trip: Trip

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                Label("Sample Itinerary", systemImage: "sparkles")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.gold)

                Text(self.message)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var message: String {
        let dayLabel = self.trip.dayCount == 1 ? "a day" : "\(self.trip.dayCount.formatted(.number)) days"
        let destination = self.trip.city.isEmpty ? self.trip.displayLocation : self.trip.city
        return "An example of \(dayLabel) in \(destination), not a suggested trip length. "
            + "Add as many days as you like and use Suggest to plan them from the city guide, "
            + "or create your own trip to replace the samples."
    }
}
