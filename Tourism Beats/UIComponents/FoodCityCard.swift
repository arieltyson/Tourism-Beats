import SwiftUI

// MARK: - FoodCityCard

struct FoodCityCard: View {
    let group: FoodJournalCityGroup

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            FoodCityCardBackground(group: self.group)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.18),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            FoodCityCardContent(group: self.group)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.45, contentMode: .fit)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.group.accessibilityLabel)
    }
}

// MARK: - FoodCityCardBackground

private struct FoodCityCardBackground: View {
    let group: FoodJournalCityGroup

    var body: some View {
        Group {
            if let imageURL = self.group.imageURL {
                CachedCityImage(url: imageURL)
            } else {
                LinearGradient(
                    colors: [
                        AppColors.info.opacity(0.95),
                        AppColors.violet.opacity(0.9),
                        AppColors.coral.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.24))
                }
            }
        }
    }
}

// MARK: - FoodCityCardContent

private struct FoodCityCardContent: View {
    let group: FoodJournalCityGroup

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Spacer()

            HStack(alignment: .bottom, spacing: SpacingTokens.small) {
                FoodCityCardText(group: self.group)

                Spacer(minLength: SpacingTokens.small)

                FoodCityCardCountBadge(count: self.group.restaurantCount)
            }
        }
        .padding(SpacingTokens.medium)
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
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)

            if !self.group.displayCountryName.isEmpty {
                Text(self.group.displayCountryName)
                    .font(TypographyTokens.artistName)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - FoodCityCardCountBadge

private struct FoodCityCardCountBadge: View {
    let count: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(self.count, format: .number)")
                .font(TypographyTokens.cardLabel.monospacedDigit())
                .bold()
                .foregroundStyle(.white)

            Text(self.count == 1 ? "restaurant" : "restaurants")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(.horizontal, SpacingTokens.small)
        .padding(.vertical, SpacingTokens.xSmall)
        .background(.thinMaterial, in: Capsule())
    }
}
