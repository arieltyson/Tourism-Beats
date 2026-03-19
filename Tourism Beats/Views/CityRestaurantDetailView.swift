import SwiftUI

// MARK: - CityRestaurantDetailView

struct CityRestaurantDetailView: View {
    let city: CityModel
    let restaurant: CityRestaurant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                Self.Hero(restaurant: self.restaurant, city: self.city)
                Self.RecommendationCard(restaurant: self.restaurant)
                Self.VisitCard(restaurant: self.restaurant)
                Self.LinkCard(restaurant: self.restaurant)
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle(self.restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CityRestaurantDetailView {
    struct Hero: View {
        let restaurant: CityRestaurant
        let city: CityModel

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Self.HeroArtwork(restaurant: self.restaurant)

                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    Text(self.restaurant.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(AppColors.label)
                        .multilineTextAlignment(.leading)

                    Text("\(self.restaurant.displayCuisine) • \(self.city.name), \(self.city.country.name)")
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
            .padding(SpacingTokens.medium)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 18,
                        y: 12
                    )
            }
        }
    }

    private struct RecommendationCard: View {
        let restaurant: CityRestaurant

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Why It Ranked Well")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.label)

                Text(self.restaurant.summary)
                    .font(TypographyTokens.body)
                    .foregroundStyle(AppColors.label)

                if !self.restaurant.rankingHighlights.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 110), spacing: SpacingTokens.xSmall)],
                        alignment: .leading,
                        spacing: SpacingTokens.xSmall
                    ) {
                        ForEach(self.restaurant.rankingHighlights, id: \.self) { highlight in
                            Text(highlight)
                                .font(TypographyTokens.footnote)
                                .foregroundStyle(AppColors.label)
                                .lineLimit(1)
                                .padding(.horizontal, SpacingTokens.small)
                                .padding(.vertical, SpacingTokens.xxSmall)
                                .background(
                                    AppColors.surfaceSecondary.opacity(0.92),
                                    in: Capsule()
                                )
                        }
                    }
                }
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

    private struct VisitCard: View {
        let restaurant: CityRestaurant

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Plan Your Visit")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.label)

                LabeledContent("Cuisine") {
                    Text(self.restaurant.displayCuisine)
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Hours") {
                    Text(self.restaurant.hours ?? "Check venue directly")
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Location") {
                    Text(self.restaurant.address ?? "Open in Maps for details")
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Phone") {
                    Text(self.restaurant.phoneNumber ?? "Check venue directly")
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Accessibility") {
                    Text(self.restaurant.wheelchairAccessibility.detailLabel)
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Dietary") {
                    Text(self.restaurant.dietarySummary ?? "Dietary options not listed")
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Outdoor Seating") {
                    Text(self.restaurant.hasOutdoorSeating ? "Listed" : "Not listed")
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                LabeledContent("Reservations") {
                    Text(self.restaurant.acceptsReservations ? "Listed" : "Not listed")
                        .multilineTextAlignment(.trailing)
                }
            }
            .font(TypographyTokens.body)
            .foregroundStyle(AppColors.label)
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

    struct LinkCard: View {
        let restaurant: CityRestaurant

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            if self.restaurant.websiteURL != nil
                || self.restaurant.mapsURL != nil
                || self.restaurant.sourceURL != nil
            {
                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    Text("Links")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    if let websiteURL = self.restaurant.websiteURL {
                        Link(destination: websiteURL) {
                            Self.LinkLabel(
                                title: "Website",
                                subtitle: websiteURL.host ?? websiteURL.absoluteString,
                                systemImage: "safari"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let mapsURL = self.restaurant.mapsURL {
                        Link(destination: mapsURL) {
                            Self.LinkLabel(
                                title: "Open in Maps",
                                subtitle: self.restaurant.address ?? self.restaurant.name,
                                systemImage: "map.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let sourceURL = self.restaurant.sourceURL {
                        Link(destination: sourceURL) {
                            Self.LinkLabel(
                                title: "Map Source",
                                subtitle: self.restaurant.sourceName,
                                systemImage: "globe.europe.africa.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
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
    }
}

extension CityRestaurantDetailView.Hero {
    private struct HeroArtwork: View {
        let restaurant: CityRestaurant

        var body: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.coral.opacity(0.78),
                            AppColors.gold.opacity(0.74),
                            AppColors.magenta.opacity(0.66)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Text(self.restaurant.rankingHighlights.first ?? "Top Pick")
                        .font(TypographyTokens.footnote)
                        .bold()
                        .foregroundStyle(AppColors.onImagePrimary)
                        .padding(.horizontal, SpacingTokens.small)
                        .padding(.vertical, SpacingTokens.xxSmall)
                        .background(AppColors.imageBadgeFill, in: Capsule())
                        .padding(SpacingTokens.medium)
                }
                .overlay {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 72, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.onImagePrimary.opacity(0.92))
                }
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .aspectRatio(4 / 3, contentMode: .fit)
        }
    }
}

extension CityRestaurantDetailView.LinkCard {
    private struct LinkLabel: View {
        let title: String
        let subtitle: String
        let systemImage: String

        var body: some View {
            HStack(spacing: SpacingTokens.small) {
                Image(systemName: self.systemImage)
                    .foregroundStyle(AppColors.coral)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.title)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text(self.subtitle)
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .padding(.horizontal, SpacingTokens.xSmall)
            .padding(.vertical, SpacingTokens.small)
            .background(
                AppColors.surfaceSecondary.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }
}
