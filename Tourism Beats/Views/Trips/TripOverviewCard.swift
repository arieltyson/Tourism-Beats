import SwiftUI

// MARK: - TripOverviewCard

struct TripOverviewCard: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title3) private var cardHeight = 214.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TripOverviewCardBackground(cityModel: self.cityModel)

            LinearGradient(
                colors: [
                    AppColors.imageScrimTop,
                    AppColors.imageScrimMid,
                    AppColors.imageScrimBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                HStack(spacing: SpacingTokens.xSmall) {
                    TripsBadge(
                        title: self.trip.status.label,
                        systemImage: self.trip.status.systemImage,
                        tint: self.trip.status.color
                    )

                    if self.trip.isSample {
                        TripsBadge(
                            title: "Sample",
                            systemImage: "sparkles",
                            tint: AppColors.gold
                        )
                    }

                    Spacer()
                }

                Spacer(minLength: SpacingTokens.medium)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.trip.name)
                        .font(TypographyTokens.songTitle)
                        .bold()
                        .foregroundStyle(AppColors.onImagePrimary)
                        .lineLimit(2)

                    Text("\(self.countryFlag) \(self.trip.displayLocation)")
                        .font(TypographyTokens.artistName)
                        .foregroundStyle(AppColors.onImageSecondary)
                        .lineLimit(1)

                    if let dateRangeLabel = self.trip.dateRangeLabel {
                        Label(dateRangeLabel, systemImage: "calendar")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(AppColors.onImageSecondary)
                    }
                }

                HStack(spacing: SpacingTokens.small) {
                    TripsFootnotePill(
                        title: self.trip.scheduleSummaryLabel,
                        systemImage: "list.bullet.rectangle"
                    )

                    if let progressLabel = self.trip.progressLabel {
                        TripsFootnotePill(
                            title: progressLabel,
                            systemImage: "checkmark.circle"
                        )
                    }
                }
            }
            .padding(SpacingTokens.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 18,
            y: 10
        )
        .contentShape(.rect(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
    }

    private var accessibilityLabel: String {
        [
            self.trip.name,
            self.trip.displayLocation,
            self.trip.status.label,
            self.trip.scheduleSummaryLabel,
            self.trip.progressLabel
        ]
        .compactMap(\.self)
        .joined(separator: ", ")
    }
}
