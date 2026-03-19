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

            Group {
                if self.viewModel.isLoading, self.viewModel.restaurants.isEmpty {
                    Self.LoadingState()
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.top, SpacingTokens.small)
        .padding(.bottom, SpacingTokens.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

                    Text("\(self.city.name), \(self.city.country.name)")
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
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 16,
                        y: 10
                    )
            }
        }
    }

    private struct PlaceholderCard: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfaceSecondary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .opacity(phase ? 0.4 : 0.8)
                } animation: { _ in
                    .easeInOut(duration: 1.0)
                }
        }
    }

    private struct LoadingState: View {
        var body: some View {
            Grid(horizontalSpacing: SpacingTokens.small, verticalSpacing: SpacingTokens.small) {
                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }

                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }

                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }
            }
            .accessibilityHidden(true)
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
            Grid(horizontalSpacing: SpacingTokens.small, verticalSpacing: SpacingTokens.small) {
                GridRow {
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 0),
                        rank: 1
                    )
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 1),
                        rank: 2
                    )
                }

                GridRow {
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 2),
                        rank: 3
                    )
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 3),
                        rank: 4
                    )
                }

                GridRow {
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 4),
                        rank: 5
                    )
                    CityRestaurantsView.CardSlot(
                        city: self.city,
                        restaurant: self.restaurant(at: 5),
                        rank: 6
                    )
                }
            }
        }

        private func restaurant(at index: Int) -> CityRestaurant? {
            guard self.restaurants.indices.contains(index) else { return nil }
            return self.restaurants[index]
        }
    }

    private struct CardSlot: View {
        let city: CityModel
        let restaurant: CityRestaurant?
        let rank: Int

        var body: some View {
            Group {
                if let restaurant {
                    NavigationLink(
                        value: CityRestaurantRoute(city: self.city, restaurant: restaurant)
                    ) {
                        RestaurantCard(restaurant: restaurant, rank: self.rank)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    struct RestaurantCard: View {
        let restaurant: CityRestaurant
        let rank: Int

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Self.backgroundGradient(for: self.restaurant).opacity(0.22))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 16,
                        y: 10
                    )

                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    HStack(alignment: .top, spacing: SpacingTokens.xSmall) {
                        Self.RankBadge(rank: self.rank)

                        Spacer(minLength: 0)

                        if let cuisine = self.restaurant.cuisine {
                            Self.CuisineBadge(cuisine: cuisine)
                        }
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: SpacingTokens.small) {
                        Circle()
                            .fill(AppColors.imageBadgeFill)
                            .frame(width: 42, height: 42)
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.onImagePrimary)
                            }

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                        Text(self.restaurant.name)
                            .font(TypographyTokens.cardLabel)
                            .bold()
                            .foregroundStyle(AppColors.label)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .padding(SpacingTokens.medium)
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(self.rank, format: .number). \(self.restaurant.name), \(self.restaurant.displayCuisine)"
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
    private struct RankBadge: View {
        let rank: Int

        var body: some View {
            Text("\(self.rank, format: .number)")
                .font(TypographyTokens.footnote.monospacedDigit())
                .bold()
                .foregroundStyle(AppColors.onImagePrimary)
                .padding(.horizontal, SpacingTokens.xSmall)
                .padding(.vertical, SpacingTokens.xxSmall)
                .background(AppColors.coral, in: Capsule())
        }
    }

    private struct CuisineBadge: View {
        let cuisine: String

        var body: some View {
            Text(self.cuisine)
                .font(TypographyTokens.footnote)
                .foregroundStyle(AppColors.label)
                .lineLimit(1)
                .padding(.horizontal, SpacingTokens.xSmall)
                .padding(.vertical, SpacingTokens.xxSmall)
                .background(
                    AppColors.surfaceSecondary.opacity(0.92),
                    in: Capsule()
                )
        }
    }
}
