import SwiftUI

// MARK: - CityRestaurantsView

struct CityRestaurantsView: View {
    let city: CityModel

    @State private var viewModel: CityRestaurantsViewModel

    init(city: CityModel) {
        self.city = city
        _viewModel = State(initialValue: CityRestaurantsViewModel(city: city))
    }

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Self.HeroCard(city: self.city)

            VStack(spacing: 0) {
                if self.viewModel.isLoading, self.viewModel.restaurants.isEmpty {
                    CardGridLoadingState()
                } else if self.viewModel.restaurants.isEmpty {
                    Self.EmptyState(
                        message: self.viewModel.statusMessage
                            ?? "No restaurant guide is available right now."
                    )
                } else {
                    Self.RestaurantGrid(
                        city: self.city,
                        restaurants: self.viewModel.restaurants
                    )
                }
            }
            .padding(.horizontal, SpacingTokens.xSmall)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.top, SpacingTokens.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .scrollsAtAccessibilitySizes()
        .background(Color.clear.ignoresSafeArea())
        .safeAreaPadding(.bottom, SpacingTokens.medium)
        .task(id: self.city.id) {
            await self.viewModel.loadIfNeeded()
        }
    }
}

extension CityRestaurantsView {
    private struct HeroCard: View {
        let city: CityModel

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                ZStack {
                    Circle()
                        .fill(AppColors.coral.opacity(0.22))

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppColors.coral)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Top Restaurants")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text(self.city.displayName)
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(SpacingTokens.medium)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .cardShadow(
                        cornerRadius: 24,
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 16,
                        y: 10
                    )
            }
        }
    }

    private struct EmptyState: View {
        let message: String

        var body: some View {
            Spacer(minLength: 0)

            ContentUnavailableView(
                "No Restaurants Yet",
                systemImage: "fork.knife.circle",
                description: Text(self.message)
            )

            Spacer(minLength: 0)
        }
    }

    private struct RestaurantGrid: View {
        let city: CityModel
        let restaurants: [CityRestaurant]

        var body: some View {
            FillingCardGrid(itemCount: self.restaurants.count) { index in
                CityRestaurantsView.CardSlot(
                    city: self.city,
                    restaurant: self.restaurants[index]
                )
            }
        }
    }

    private struct CardSlot: View {
        let city: CityModel
        let restaurant: CityRestaurant

        var body: some View {
            NavigationLink(
                value: CityRestaurantRoute(city: self.city, restaurant: self.restaurant)
            ) {
                RestaurantCard(restaurant: self.restaurant)
            }
            .buttonStyle(.plain)
        }
    }

    struct RestaurantCard: View {
        let restaurant: CityRestaurant

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            ZStack {
                if self.restaurant.latitude != nil, self.restaurant.longitude != nil {
                    RestaurantPreviewImage(
                        restaurant: self.restaurant,
                        snapshotSize: CGSize(width: 180, height: 135)
                    )
                } else {
                    Self.backgroundGradient(for: self.restaurant)
                }

                // The scrim alone keeps the cuisine and name legible over any
                // photo or map, as on the activity cards.
                LinearGradient(
                    colors: [
                        AppColors.imageScrimTop.opacity(0.02),
                        AppColors.imageScrimMid.opacity(0.52),
                        AppColors.imageScrimBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                        if let cuisine = self.restaurant.cuisine {
                            Self.CuisineLabel(cuisine: cuisine)
                        }

                        Text(self.restaurant.name)
                            .font(TypographyTokens.cardLabel)
                            .bold()
                            .foregroundStyle(AppColors.onImagePrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SpacingTokens.medium)
            }
            .clipShape(.rect(cornerRadius: GuideCardTokens.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GuideCardTokens.cornerRadius, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.scheme),
                        lineWidth: GuideCardTokens.borderWidth
                    )
            }
            .cardShadow(
                cornerRadius: GuideCardTokens.cornerRadius,
                color: AppColors.glassShadow(for: self.scheme),
                radius: GuideCardTokens.shadowRadius,
                y: GuideCardTokens.shadowY
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(self.restaurant.name), \(self.restaurant.displayCuisine)"
            )
            .accessibilityHint("Opens the restaurant details")
        }

        private static func backgroundGradient(for restaurant: CityRestaurant) -> LinearGradient {
            let palettes: [[Color]] = [
                [AppColors.coral, AppColors.gold],
                [AppColors.info, AppColors.safe],
                [AppColors.magenta, AppColors.coral],
                [AppColors.violet, AppColors.info]
            ]
            let index = Int(UInt(bitPattern: restaurant.id.hashValue) % UInt(palettes.count))
            let palette = palettes[index]

            return LinearGradient(
                colors: [
                    palette[0],
                    palette[1]
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension CityRestaurantsView.RestaurantCard {
    /// The cuisine as a quiet line above the name.
    private struct CuisineLabel: View {
        let cuisine: String

        var body: some View {
            Text(self.cuisine)
                .font(TypographyTokens.footnote)
                .bold()
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onImageSecondary)
                .lineLimit(1)
        }
    }
}
