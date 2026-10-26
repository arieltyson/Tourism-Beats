import SwiftUI

// MARK: - TripsEmptyState

struct TripsEmptyState: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let showsSampleTrips: Bool
    let onCreateTrip: () -> Void
    let onRestoreSamples: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.large) {
            Image(systemName: "suitcase.rolling.fill")
                .font(.system(size: 62))
                .foregroundStyle(AppColors.coral.opacity(0.72))
                .symbolEffect(
                    .pulse,
                    options: .repeating,
                    isActive: !self.reduceMotion
                )

            VStack(spacing: SpacingTokens.xSmall) {
                Text("Plan Trips Your Way")
                    .font(TypographyTokens.songTitle)
                    .bold()
                    .foregroundStyle(.primary)

                Text(self.supportingCopy)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            VStack(spacing: SpacingTokens.small) {
                Button("Create Trip", systemImage: "plus") {
                    self.onCreateTrip()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.coral)
                .accessibilityInputLabels(["Create Trip", "Add Trip"])

                if self.showsSampleTrips {
                    Button("Load Sample Trips", systemImage: "sparkles") {
                        self.onRestoreSamples()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityInputLabels(["Load Sample Trips", "Restore Sample Trips"])
                }
            }

            if self.showsSampleTrips {
                HStack(spacing: SpacingTokens.xSmall) {
                    TripsSampleNamePill(title: "Trinidad and Tobago")
                    TripsSampleNamePill(title: "Vancouver, BC")
                    TripsSampleNamePill(title: "San Francisco")
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }

    private var supportingCopy: String {
        if self.showsSampleTrips {
            return "Keep rough sketches, detailed day plans, or both. Start with your own trip or load the sample itineraries."
        }

        return "Keep rough sketches or detailed day plans, then build each trip around the way you actually travel."
    }
}
