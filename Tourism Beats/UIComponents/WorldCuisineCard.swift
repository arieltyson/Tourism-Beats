import SwiftUI

// MARK: - WorldCuisineCard

/// A ranked cuisine over a photo of a dish it's known for.
struct WorldCuisineCard: View {
    let cuisine: WorldCuisine
    var isLeading = false

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title3) private var leadingHeight = FoodJournalTokens.leadingCuisineCardHeight
    @ScaledMetric(relativeTo: .title3) private var height = FoodJournalTokens.cuisineCardHeight

    var body: some View {
        let radius = FoodJournalTokens.cardCornerRadius
        ZStack(alignment: .bottomLeading) {
            WorldCuisineCardBackground(imageURL: self.cuisine.imageURL)
            WorldCuisineCardScrim()
            WorldCuisineCardContent(cuisine: self.cuisine, isLeading: self.isLeading)
                .padding(SpacingTokens.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.isLeading ? self.leadingHeight : self.height)
        .clipShape(.rect(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(AppColors.glassBorder(for: self.colorScheme), lineWidth: 0.5)
        }
        .cardShadow(cornerRadius: radius, color: AppColors.glassShadow(for: self.colorScheme), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.cuisine.accessibilityLabel)
    }
}

// MARK: - WorldCuisineCardBackground

private struct WorldCuisineCardBackground: View {
    let imageURL: URL?

    var body: some View {
        Rectangle()
            .fill(AppColors.coral.gradient)
            .overlay {
                if let imageURL = self.imageURL {
                    CachedCityImage(url: imageURL)
                }
            }
            .clipped()
    }
}

// MARK: - WorldCuisineCardScrim

/// Darkens the photo's lower half, where the cuisine is named.
private struct WorldCuisineCardScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.35), location: 0),
                .init(color: .clear, location: 0.3),
                .init(color: .black.opacity(0.3), location: 0.55),
                .init(color: .black.opacity(0.75), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - WorldCuisineCardContent

private struct WorldCuisineCardContent: View {
    let cuisine: WorldCuisine
    let isLeading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.cuisine.rank, format: .number)
                .font(self.isLeading ? TypographyTokens.heroTitle : TypographyTokens.songTitle)
                .bold()
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(AppColors.onImagePrimary)

            Spacer(minLength: 0)

            Text("\(self.cuisine.flag) \(self.cuisine.name)")
                .font(self.isLeading ? TypographyTokens.songTitle : TypographyTokens.sectionHeader)
                .bold()
                .foregroundStyle(AppColors.onImagePrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(self.cuisine.signatureDish)
                .font(self.isLeading ? TypographyTokens.cardLabel : TypographyTokens.caption)
                .foregroundStyle(AppColors.onImageSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }
}
