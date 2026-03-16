import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    let onExplore: () -> Void
    let onCitySelected: (CityModel) -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var haptic = HapticTrigger()

    var body: some View {
        ZStack {
            EarthView()
                .ignoresSafeArea()
                .opacity(self.globeOpacity)

            AppGradients.vignette
                .ignoresSafeArea()
                .opacity(self.globeOpacity)

            ScrollView(.vertical) {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    LazyVStack(spacing: 20) {
                        // Header
                        HomeHeaderSection()
                            .padding(.top, 60)

                        if self.viewModel.isLoaded,
                           !self.viewModel.featuredCities.isEmpty
                        {
                            // Hero card
                            DiscoveryHeroCard(
                                city: self.viewModel.featuredCities[0],
                                localTime: self.viewModel.localTime(
                                    for: self.viewModel.featuredCities[0]
                                ),
                                scheme: self.scheme
                            ) {
                                self.haptic.fire(.citySelect)
                                self.onCitySelected(self.viewModel.featuredCities[0])
                            }

                            // City grid
                            let gridCities = Array(
                                self.viewModel.featuredCities.dropFirst().prefix(6)
                            )
                            LazyVGrid(columns: self.gridColumns, spacing: 14) {
                                ForEach(gridCities) { city in
                                    DiscoveryCityCard(
                                        city: city,
                                        localTime: self.viewModel.localTime(for: city),
                                        scheme: self.scheme
                                    ) {
                                        self.haptic.fire(.citySelect)
                                        self.onCitySelected(city)
                                    }
                                }
                            }

                            // Last featured city as a wide card
                            if self.viewModel.featuredCities.count > 7 {
                                let lastCity = self.viewModel.featuredCities[7]
                                DiscoveryCityCard(
                                    city: lastCity,
                                    localTime: self.viewModel.localTime(for: lastCity),
                                    scheme: self.scheme
                                ) {
                                    self.haptic.fire(.citySelect)
                                    self.onCitySelected(lastCity)
                                }
                            }

                            // Explore CTA
                            DiscoveryCTACard(
                                cityCount: self.viewModel.allCityCount,
                                scheme: self.scheme
                            ) {
                                self.haptic.fire(.searchOpen)
                                self.onExplore()
                            }
                        }

                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal, self.horizontalPadding)
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: proxy.frame(in: .named("homeScroll")).minY
                            )
                    }
                )
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "homeScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                if !self.reduceMotion {
                    self.scrollOffset = value
                }
            }
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

    // MARK: - Computed Properties

    private var globeOpacity: Double {
        if self.reduceMotion { return 0.6 }
        let normalized = min(max(-self.scrollOffset / 200, 0), 1)
        return 1.0 - (normalized * 0.6)
    }

    private var gridColumns: [GridItem] {
        if self.typeSize >= .accessibility1 {
            [GridItem(.flexible())]
        } else {
            [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ]
        }
    }

    private var horizontalPadding: CGFloat {
        self.typeSize >= .accessibility1 ? 20 : 24
    }
}

// MARK: - HomeHeaderSection

private struct HomeHeaderSection: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Tourism Beats")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .kerning(0.5)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                .accessibilityAddTraits(.isHeader)

            Text("an immersive tourist experience")
                .font(.system(.title3, design: .rounded).italic())
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 1)
        }
    }
}

// MARK: - DiscoveryHeroCard

private struct DiscoveryHeroCard: View {
    let city: CityModel
    let localTime: String
    let scheme: ColorScheme
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var cardHeight: CGFloat {
        self.typeSize >= .accessibility1 ? 320 : 280
    }

    var body: some View {
        Button(action: self.action) {
            ZStack(alignment: .bottomLeading) {
                Image(self.city.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: self.cardHeight)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(self.city.country.flag)
                        .font(.title2)

                    Text(self.city.name)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: 8) {
                        Text(self.city.country.name)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))

                        Text("\u{00B7}")
                            .foregroundStyle(.white.opacity(0.5))

                        Text(self.localTime)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(20)
            }
            .frame(height: self.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.scheme),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppColors.glassShadow(for: self.scheme),
                radius: 18,
                y: 6
            )
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel(
            "\(self.city.country.flag) \(self.city.name), \(self.city.country.name). Local time \(self.localTime)"
        )
        .accessibilityHint("Opens city details")
    }
}

// MARK: - DiscoveryCityCard

private struct DiscoveryCityCard: View {
    let city: CityModel
    let localTime: String
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            ZStack(alignment: .bottomLeading) {
                Image(self.city.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(self.city.country.flag)
                            .font(.callout)

                        Text(self.city.name)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(self.localTime)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(14)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.scheme),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppColors.glassShadow(for: self.scheme),
                radius: 18,
                y: 6
            )
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel(
            "\(self.city.country.flag) \(self.city.name), \(self.city.country.name). Local time \(self.localTime)"
        )
        .accessibilityHint("Opens city details")
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
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)

                    Text("\(self.cityCount) cities worldwide")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 18,
                        y: 6
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .accessibilityLabel("Explore all destinations. \(self.cityCount) cities worldwide.")
        .accessibilityHint("Opens the search tab to explore destinations")
    }
}

// MARK: - CardPressStyle

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

// MARK: - ScrollOffsetKey

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
