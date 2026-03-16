import SwiftUI

// MARK: - FoodCityCard

struct FoodCityCard: View {
    let group: FoodJournalCityGroup

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title3) private var cardHeight = 188.0
    @ScaledMetric(relativeTo: .caption) private var badgeMinWidth = 88.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FoodCityCardBackground(group: self.group)

            FoodCityCardVignette()

            FoodCityCardText(group: self.group, badgeInsetWidth: self.badgeMinWidth)
        }
        .overlay(alignment: .bottomTrailing) {
            FoodCityCardCountBadge(
                count: self.group.restaurantCount,
                minWidth: self.badgeMinWidth
            )
            .padding(SpacingTokens.small)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight)
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.75
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 16,
            y: 8
        )
        .contentShape(.rect(cornerRadius: 26, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.group.accessibilityLabel)
    }
}

// MARK: - FoodCityCardBackground

private struct FoodCityCardBackground: View {
    let group: FoodJournalCityGroup

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            if let imageURL = self.group.imageURL {
                CachedCityImage(url: imageURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        AppColors.info.opacity(0.92),
                        AppColors.violet.opacity(0.88),
                        AppColors.coral.opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.24))
                }
            }
        }
    }
}

// MARK: - FoodCityCardVignette

private struct FoodCityCardVignette: View {
    var body: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.08),
                .clear,
                .black.opacity(0.68)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.12),
                    .black.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - FoodCityCardText

private struct FoodCityCardText: View {
    let group: FoodJournalCityGroup
    let badgeInsetWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.group.displayCityName)
                .font(TypographyTokens.songTitle)
                .bold()
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.88)
                .shadow(color: .black.opacity(0.28), radius: 10, y: 4)

            if !self.group.displayCountryName.isEmpty {
                Text(self.group.displayCountryName)
                    .font(TypographyTokens.artistName)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SpacingTokens.small)
        .padding(.trailing, self.badgeInsetWidth + SpacingTokens.large)
    }
}

// MARK: - FoodCityCardCountBadge

private struct FoodCityCardCountBadge: View {
    let count: Int
    let minWidth: CGFloat

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(self.count, format: .number)")
                .font(TypographyTokens.cardLabel.monospacedDigit())
                .bold()
                .foregroundStyle(.white)

            Text(self.count == 1 ? "restaurant" : "restaurants")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.84))
        }
        .frame(minWidth: self.minWidth, alignment: .trailing)
        .padding(.horizontal, SpacingTokens.small)
        .padding(.vertical, SpacingTokens.xSmall)
        .background(.thinMaterial, in: Capsule())
    }
}
