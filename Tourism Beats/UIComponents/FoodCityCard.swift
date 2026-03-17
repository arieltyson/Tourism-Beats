import SwiftUI

// MARK: - FoodCityCard

struct FoodCityCard: View {
    let group: FoodJournalCityGroup

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .title3) private var standardCardHeight = 212.0
    @ScaledMetric(relativeTo: .title3) private var accessibilityCardHeight = 260.0
    @ScaledMetric(relativeTo: .caption) private var badgeMinWidth = 92.0
    @ScaledMetric(relativeTo: .body) private var standardFooterMinHeight = 104.0
    @ScaledMetric(relativeTo: .body) private var accessibilityFooterMinHeight = 152.0

    var body: some View {
        ZStack {
            FoodCityCardBackground(group: self.group)

            FoodCityCardVignette()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                FoodCityCardFooter(
                    group: self.group,
                    badgeMinWidth: self.badgeMinWidth,
                    footerMinHeight: self.footerMinHeight
                )
            }
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

    private var cardHeight: CGFloat {
        self.dynamicTypeSize.isAccessibilitySize
            ? self.accessibilityCardHeight
            : self.standardCardHeight
    }

    private var footerMinHeight: CGFloat {
        self.dynamicTypeSize.isAccessibilitySize
            ? self.accessibilityFooterMinHeight
            : self.standardFooterMinHeight
    }
}

// MARK: - FoodCityCardBackground

private struct FoodCityCardBackground: View {
    let group: FoodJournalCityGroup

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
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
                AppColors.imageScrimTop,
                .clear,
                AppColors.imageScrimMid
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    .clear,
                    AppColors.imageScrimMid,
                    AppColors.imageScrimBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - FoodCityCardFooter

private struct FoodCityCardFooter: View {
    let group: FoodJournalCityGroup
    let badgeMinWidth: CGFloat
    let footerMinHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    .clear,
                    AppColors.imageScrimMid,
                    AppColors.imageScrimBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            FoodCityCardFooterContent(
                group: self.group,
                badgeMinWidth: self.badgeMinWidth
            )
            .padding(.horizontal, SpacingTokens.small)
            .padding(.bottom, SpacingTokens.small)
            .padding(.top, SpacingTokens.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: self.footerMinHeight, alignment: .bottom)
    }
}

// MARK: - FoodCityCardFooterContent

private struct FoodCityCardFooterContent: View {
    let group: FoodJournalCityGroup
    let badgeMinWidth: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            FoodCityCardVerticalFooterContent(
                group: self.group,
                badgeMinWidth: self.badgeMinWidth
            )
        } else {
            ViewThatFits(in: .horizontal) {
                FoodCityCardHorizontalFooterContent(
                    group: self.group,
                    badgeMinWidth: self.badgeMinWidth
                )

                FoodCityCardVerticalFooterContent(
                    group: self.group,
                    badgeMinWidth: self.badgeMinWidth
                )
            }
        }
    }
}

// MARK: - FoodCityCardHorizontalFooterContent

private struct FoodCityCardHorizontalFooterContent: View {
    let group: FoodJournalCityGroup
    let badgeMinWidth: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: SpacingTokens.small) {
            FoodCityCardText(group: self.group)

            Spacer(minLength: SpacingTokens.small)

            FoodCityCardCountBadge(
                count: self.group.restaurantCount,
                minWidth: self.badgeMinWidth
            )
        }
    }
}

// MARK: - FoodCityCardVerticalFooterContent

private struct FoodCityCardVerticalFooterContent: View {
    let group: FoodJournalCityGroup
    let badgeMinWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            FoodCityCardText(group: self.group)

            FoodCityCardCountBadge(
                count: self.group.restaurantCount,
                minWidth: self.badgeMinWidth
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FoodCityCardText

private struct FoodCityCardText: View {
    let group: FoodJournalCityGroup

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.group.displayCityName)
                .font(TypographyTokens.songTitle)
                .bold()
                .foregroundStyle(AppColors.onImagePrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .shadow(color: .black.opacity(0.28), radius: 10, y: 4)

            if !self.group.displayCountryName.isEmpty {
                Text(self.group.displayCountryName)
                    .font(TypographyTokens.artistName)
                    .foregroundStyle(AppColors.onImageSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .foregroundStyle(AppColors.onImagePrimary)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 2)

            Text(self.count == 1 ? "restaurant" : "restaurants")
                .font(TypographyTokens.footnote)
                .foregroundStyle(AppColors.onImageSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
        }
        .frame(minWidth: self.minWidth, alignment: .trailing)
        .padding(.horizontal, SpacingTokens.small)
        .padding(.vertical, SpacingTokens.xSmall)
        .background {
            Capsule()
                .fill(AppColors.imageBadgeFill)
                .overlay {
                    Capsule()
                        .strokeBorder(AppColors.imageBadgeBorder, lineWidth: 1)
                }
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}
