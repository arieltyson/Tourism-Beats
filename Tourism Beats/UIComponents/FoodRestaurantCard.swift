import SwiftUI

// MARK: - FoodRestaurantCard

struct FoodRestaurantCard: View {
    let restaurant: Restaurant
    let mealPhotos: [RestaurantMealPhoto]

    @Environment(\.colorScheme) private var colorScheme

    init(
        restaurant: Restaurant,
        mealPhotos: [RestaurantMealPhoto] = []
    ) {
        self.restaurant = restaurant
        self.mealPhotos = mealPhotos
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            if let leadMealPhoto = self.mealPhotos.first {
                FoodRestaurantMealPhotoPreview(
                    mealPhoto: leadMealPhoto,
                    additionalPhotoCount: max(0, self.mealPhotos.count - 1)
                )
            }

            FoodRestaurantCardHeader(restaurant: self.restaurant)

            if let score = self.restaurant.clampedScore {
                FoodRestaurantScoreView(score: score)
            }

            FoodRestaurantCuisineRow(cuisine: self.restaurant.displayCuisine)

            if let notes = self.restaurant.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                Text(notes)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(SpacingTokens.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 8,
            y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [self.restaurant.name, self.restaurant.status.label]
        if let score = self.restaurant.clampedScore {
            parts.append("\(score) out of 10")
        }
        parts.append("Cuisine: \(self.restaurant.displayCuisine.label)")
        if let dish = self.restaurant.bestDish,
           !dish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            parts.append("Best dish: \(dish)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - FoodRestaurantCardHeader

private struct FoodRestaurantCardHeader: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(self.restaurant.name)
                .font(TypographyTokens.songTitle)
                .bold()
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: SpacingTokens.xSmall)

            FoodRestaurantStatusBadge(status: self.restaurant.status)
        }
    }
}

// MARK: - FoodRestaurantMealPhotoPreview

private struct FoodRestaurantMealPhotoPreview: View {
    let mealPhoto: RestaurantMealPhoto
    let additionalPhotoCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(
                url: RestaurantMealPhotoStore.fileURL(for: self.mealPhoto.relativePath),
                transaction: .init(animation: .smooth)
            ) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.45, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 14, style: .continuous))

            if self.additionalPhotoCount > 0 {
                Text("+\(self.additionalPhotoCount, format: .number)")
                    .font(TypographyTokens.footnote.monospacedDigit())
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, SpacingTokens.xSmall)
                    .padding(.vertical, SpacingTokens.xxSmall)
                    .background(.thinMaterial, in: Capsule())
                    .padding(SpacingTokens.xSmall)
            }
        }
    }
}

// MARK: - FoodRestaurantStatusBadge

private struct FoodRestaurantStatusBadge: View {
    let status: RestaurantStatus

    private var badgeColor: Color {
        switch self.status {
        case .wantToTry:
            AppColors.coral
        case .tried:
            AppColors.safe
        }
    }

    var body: some View {
        HStack(spacing: SpacingTokens.xxSmall) {
            Image(systemName: self.status.systemImage)
                .font(.caption2)

            Text(self.status.label)
                .font(.caption2)
                .bold()
        }
        .foregroundStyle(self.badgeColor)
        .padding(.horizontal, SpacingTokens.xSmall)
        .padding(.vertical, SpacingTokens.xxSmall)
        .background(self.badgeColor.opacity(0.15), in: Capsule())
    }
}

// MARK: - FoodRestaurantScoreView

private struct FoodRestaurantScoreView: View {
    let score: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1 ... 10, id: \.self) { index in
                Circle()
                    .fill(
                        index <= self.score
                            ? AnyShapeStyle(AppColors.gold)
                            : AnyShapeStyle(.quaternary)
                    )
                    .frame(width: 8, height: 8)
            }

            Text("\(self.score, format: .number)/10")
                .font(.caption2.monospacedDigit())
                .bold()
                .foregroundStyle(AppColors.gold)
                .padding(.leading, SpacingTokens.xxSmall)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.score) out of 10")
    }
}

// MARK: - FoodRestaurantCuisineRow

private struct FoodRestaurantCuisineRow: View {
    let cuisine: RestaurantCuisine

    var body: some View {
        HStack(spacing: SpacingTokens.xxSmall) {
            Image(systemName: "fork.knife")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(self.cuisine.label)
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
                .italic()
                .lineLimit(1)
        }
    }
}
