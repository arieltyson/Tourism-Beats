import SwiftUI

// MARK: - FoodRestaurantCard

struct FoodRestaurantCard: View {
    let restaurant: Restaurant
    let mealPhotos: [RestaurantMealPhoto]
    let onEdit: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        restaurant: Restaurant,
        mealPhotos: [RestaurantMealPhoto] = [],
        onEdit: @escaping () -> Void
    ) {
        self.restaurant = restaurant
        self.mealPhotos = mealPhotos
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            if let leadMealPhoto = self.mealPhotos.first {
                FoodRestaurantMealPhotoPreview(
                    mealPhoto: leadMealPhoto,
                    additionalPhotoCount: max(0, self.mealPhotos.count - 1)
                )
            }

            FoodRestaurantCardHeader(restaurant: self.restaurant, onEdit: self.onEdit)

            if let score = self.restaurant.clampedScore {
                FoodRestaurantScoreView(score: score)
            }

            FoodRestaurantCuisineRow(cuisine: self.restaurant.displayCuisine)

            if let bestDish = self.restaurant.bestDish,
               !bestDish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                HStack(spacing: SpacingTokens.xxSmall) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.gold)

                    Text("Best dish: \(bestDish)")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

            if let notes = self.restaurant.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                Text(notes)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            FoodRestaurantLinksRow(restaurant: self.restaurant)
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
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.xSmall) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: SpacingTokens.small) {
                    FoodRestaurantTitleText(name: self.restaurant.name)

                    Spacer(minLength: SpacingTokens.xSmall)

                    FoodRestaurantStatusBadge(status: self.restaurant.status)
                }

                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    FoodRestaurantTitleText(name: self.restaurant.name)
                    FoodRestaurantStatusBadge(status: self.restaurant.status)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                self.onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Edit restaurant")
        }
    }
}

// MARK: - FoodRestaurantTitleText

private struct FoodRestaurantTitleText: View {
    let name: String

    var body: some View {
        Text(self.name)
            .font(TypographyTokens.songTitle)
            .bold()
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - FoodRestaurantMealPhotoPreview

private struct FoodRestaurantMealPhotoPreview: View {
    private static let previewAspectRatio: CGFloat = 1.45
    private static let cornerRadius: CGFloat = 14

    let mealPhoto: RestaurantMealPhoto
    let additionalPhotoCount: Int

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .frame(maxWidth: .infinity)
            .aspectRatio(Self.previewAspectRatio, contentMode: .fit)
            .overlay {
                self.photoContent
            }
            .clipShape(.rect(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if self.additionalPhotoCount > 0 {
                    self.additionalPhotoBadge
                }
            }
    }

    @ViewBuilder
    private var photoContent: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var additionalPhotoBadge: some View {
        Text("+\(self.additionalPhotoCount, format: .number)")
            .font(TypographyTokens.footnote.monospacedDigit())
            .bold()
            .foregroundStyle(AppColors.onImagePrimary)
            .padding(.horizontal, SpacingTokens.xSmall)
            .padding(.vertical, SpacingTokens.xxSmall)
            .background(AppColors.imageBadgeFill, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppColors.imageBadgeBorder, lineWidth: 1)
            }
            .padding(SpacingTokens.xSmall)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.status.label)
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

// MARK: - FoodRestaurantLinksRow

private struct FoodRestaurantLinksRow: View {
    let restaurant: Restaurant

    var body: some View {
        let hasLocation = self.restaurant.locationURL != nil
        let hasMenu = self.restaurant.menuURL != nil

        if hasLocation || hasMenu {
            HStack(spacing: SpacingTokens.small) {
                if let locationURL = self.restaurant.locationURL {
                    Link(destination: locationURL) {
                        Label("Location", systemImage: "map.fill")
                            .font(TypographyTokens.caption)
                            .bold()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.coral)
                }

                if let menuURL = self.restaurant.menuURL {
                    Link(destination: menuURL) {
                        Label("Menu", systemImage: "menucard.fill")
                            .font(TypographyTokens.caption)
                            .bold()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.coral)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, SpacingTokens.xxSmall)
        }
    }
}
