import SwiftUI

// MARK: - TripHeroCard

struct TripHeroCard: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 280.0

    var body: some View {
        // The card grows past its base height when larger text needs the room,
        // so the status and sample badges are never pushed out of view.
        TripHeroMinimumHeightLayout(minHeight: self.cardHeight) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                TripHeroBadgeLayout(trip: self.trip)

                Spacer(minLength: SpacingTokens.large)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.trip.name)
                        .font(TypographyTokens.heroTitle)
                        .bold()
                        .foregroundStyle(AppColors.onImagePrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)

                    Text("\(self.countryFlag) \(self.trip.displayLocation)")
                        .font(TypographyTokens.songTitle)
                        .foregroundStyle(AppColors.onImageSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let dateRangeLabel = self.trip.dateRangeLabel {
                        Label(dateRangeLabel, systemImage: "calendar")
                            .font(TypographyTokens.body)
                            .foregroundStyle(AppColors.onImageSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                TripHeroFootnoteLayout(trip: self.trip)
            }
            .padding(SpacingTokens.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            ZStack {
                TripHeroBackground(cityModel: self.cityModel)

                LinearGradient(
                    colors: [
                        AppColors.imageScrimTop,
                        AppColors.imageScrimMid,
                        AppColors.imageScrimBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(.rect(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
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
    }
}
