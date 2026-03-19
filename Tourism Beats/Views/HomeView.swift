import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    let onExplore: () -> Void
    let onCitySelected: (CityModel) -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var viewModel = HomeViewModel()
    @State private var haptic = HapticTrigger()

    var body: some View {
        ZStack {
            EarthView()
                .ignoresSafeArea()

            AppGradients.vignette
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                HomeHeaderSection()

                Spacer()
                    .frame(height: 28)

                // Featured city cards
                if self.viewModel.isLoaded,
                   !self.viewModel.featuredCities.isEmpty
                {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        HomeFeaturedCitiesCarousel(
                            featuredCities: self.viewModel.featuredCities,
                            scheme: self.scheme,
                            horizontalPadding: self.horizontalPadding,
                            localTime: { city in
                                self.viewModel.localTime(for: city)
                            },
                            onSelectCity: { city in
                                self.haptic.fire(.citySelect)
                                self.onCitySelected(city)
                            }
                        )
                    }
                }

                Spacer()
                    .frame(height: 20)

                // Explore CTA
                DiscoveryCTACard(
                    cityCount: self.viewModel.allCityCount,
                    scheme: self.scheme
                ) {
                    self.haptic.fire(.searchOpen)
                    self.onExplore()
                }
                .padding(.horizontal, self.horizontalPadding)

                Spacer()
                    .frame(height: 16)
            }
            .safeAreaPadding(.bottom, 16)
        }
        .sensoryFeedback(self.haptic.feedback, trigger: self.haptic)
        .navigationBarBackButtonHidden(true)
        .task {
            self.viewModel.loadCities()
            if self.viewModel.isLoaded {
                AccessibilityAnnouncer.announceDiscoveryLoaded(
                    count: self.viewModel.featuredCities.count
                )
            }
        }
    }

    // MARK: - Layout Constants

    private var horizontalPadding: CGFloat {
        self.typeSize >= .accessibility1 ? 20 : 24
    }
}

// MARK: - HomeFeaturedCitiesCarousel

private struct HomeFeaturedCitiesCarousel: View {
    let featuredCities: [CityModel]
    let scheme: ColorScheme
    let horizontalPadding: CGFloat
    let localTime: (CityModel) -> String
    let onSelectCity: (CityModel) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let cardSpacing: CGFloat = 10

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Self.cardSpacing) {
                ForEach(self.featuredCities) { city in
                    DiscoveryCityCard(
                        city: city,
                        localTime: self.localTime(city),
                        scheme: self.scheme
                    ) {
                        self.onSelectCity(city)
                    }
                    .containerRelativeFrame(
                        .horizontal,
                        count: self.columnCount,
                        span: Self.columnSpan,
                        spacing: Self.cardSpacing
                    )
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, self.horizontalPadding, for: .scrollContent)
        .scrollClipDisabled()
        .scrollTargetBehavior(
            .viewAligned(limitBehavior: .alwaysByOne, anchor: .leading)
        )
        .scrollIndicators(.hidden)
    }

    private static let columnSpan = 2

    private var columnCount: Int {
        self.dynamicTypeSize >= .accessibility1 ? 3 : 5
    }
}

// MARK: - HomeHeaderSection

private struct HomeHeaderSection: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Tourism Beats")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .kerning(0.5)
                .foregroundStyle(AppColors.onImagePrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                .accessibilityAddTraits(.isHeader)

            Text("an immersive tourist experience")
                .font(.system(.title3, design: .rounded).italic())
                .foregroundStyle(AppColors.onImageSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 1)
        }
    }
}

// MARK: - DiscoveryCityCard

private struct DiscoveryCityCard: View {
    let city: CityModel
    let localTime: String
    let scheme: ColorScheme
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: self.action) {
            ZStack(alignment: .bottomLeading) {
                CachedCityImage(url: self.city.imageURL, fallbackCoordinate: self.city.coordinate)
                    .frame(height: self.cardHeight)
                    .clipped()

                LinearGradient(
                    colors: [AppColors.imageScrimTop, AppColors.imageScrimBottom],
                    startPoint: UnitPoint(x: 0.5, y: 0.3),
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(self.city.country.flag)
                            .font(.callout)

                        Text(self.city.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppColors.onImagePrimary)
                            .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                            .minimumScaleFactor(0.75)
                    }

                    Text(self.localTime)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(AppColors.onImageSecondary)
                        .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
                .padding(12)
            }
            .frame(height: self.cardHeight)
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.scheme),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppColors.glassShadow(for: self.scheme),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel(
            "\(self.city.country.flag) \(self.city.name), \(self.city.country.name). Local time \(self.localTime)"
        )
        .accessibilityHint("Opens city details")
        .accessibilityInputLabels(["\(self.city.name)", "Open \(self.city.name)"])
    }

    private var cardHeight: CGFloat {
        self.dynamicTypeSize.isAccessibilitySize ? 168 : 140
    }
}

// MARK: - DiscoveryCTACard

private struct DiscoveryCTACard: View {
    let cityCount: Int
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore all destinations")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppColors.onImagePrimary)

                    Text("\(self.cityCount) cities worldwide")
                        .font(.caption)
                        .foregroundStyle(AppColors.onImageSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColors.onImagePrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.imageBadgeFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                AppColors.imageBadgeBorder,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 12,
                        y: 4
                    )
            )
            .contentShape(.rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel("Explore all destinations. \(self.cityCount) cities worldwide.")
        .accessibilityHint("Opens the search tab to explore destinations")
    }
}

// MARK: - CardPressStyle

private struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                self.reduceMotion ? 1.0 : (configuration.isPressed ? 0.97 : 1.0)
            )
            .opacity(
                self.reduceMotion ? 1.0 : (configuration.isPressed ? 0.9 : 1.0)
            )
            .animation(
                self.reduceMotion
                    ? .none
                    : .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}
