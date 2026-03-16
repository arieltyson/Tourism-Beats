import SwiftUI

// MARK: - FoodRestaurantCard

struct FoodRestaurantCard: View {
    let restaurant: Restaurant

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
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
