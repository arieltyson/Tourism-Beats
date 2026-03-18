import SwiftUI

// MARK: - FoodCityCard

struct FoodCityCard: View {
    let group: FoodJournalCityGroup

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .title3) private var standardCardHeight = 220.0
    @ScaledMetric(relativeTo: .title3) private var accessibilityCardHeight = 280.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FoodCityCardBackground(group: self.group)

            FoodCityCardScrim()

            FoodCityCardContent(group: self.group)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight)
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 12,
            y: 6
        )
        .contentShape(.rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.group.accessibilityLabel)
    }

    private var cardHeight: CGFloat {
        self.dynamicTypeSize.isAccessibilitySize
            ? self.accessibilityCardHeight
            : self.standardCardHeight
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

// MARK: - FoodCityCardScrim

private struct FoodCityCardScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.3),
                .init(color: .black.opacity(0.25), location: 0.6),
                .init(color: .black.opacity(0.65), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - FoodCityCardContent

private struct FoodCityCardContent: View {
    let group: FoodJournalCityGroup

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            self.verticalLayout
        } else {
            self.horizontalLayout
        }
    }

    private var horizontalLayout: some View {
        HStack(alignment: .bottom) {
            self.cityInfo

            Spacer(minLength: SpacingTokens.xSmall)

            FoodCityCardCountBadge(count: self.group.restaurantCount)
        }
        .padding(SpacingTokens.medium)
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            self.cityInfo

            FoodCityCardCountBadge(count: self.group.restaurantCount)
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var cityInfo: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.group.displayCityName)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

            if !self.group.displayCountryName.isEmpty {
                Text(self.group.displayCountryName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            }
        }
    }
}

// MARK: - FoodCityCardCountBadge

private struct FoodCityCardCountBadge: View {
    let count: Int

    var body: some View {
        Text("\(self.count) \(self.count == 1 ? "restaurant" : "restaurants")")
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}
