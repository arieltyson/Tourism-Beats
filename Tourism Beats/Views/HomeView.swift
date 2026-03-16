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
                        self.featuredCardsLayout
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

    // MARK: - Featured Cards Layout

    private var featuredCardsLayout: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(self.viewModel.featuredCities) { city in
                    DiscoveryCityCard(
                        city: city,
                        localTime: self.viewModel.localTime(for: city),
                        scheme: self.scheme
                    ) {
                        self.haptic.fire(.citySelect)
                        self.onCitySelected(city)
                    }
                    .frame(width: self.cardWidth)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, self.horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }

    private var cardWidth: CGFloat {
        self.typeSize >= .accessibility1 ? 200 : 160
    }

    // MARK: - Layout Constants

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

// MARK: - DiscoveryCityCard

private struct DiscoveryCityCard: View {
    let city: CityModel
    let localTime: String
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            ZStack(alignment: .bottomLeading) {
                CachedCityImage(url: self.city.imageURL)
                    .frame(height: 140)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: UnitPoint(x: 0.5, y: 0.3),
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(self.city.country.flag)
                            .font(.callout)

                        Text(self.city.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Text(self.localTime)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(12)
            }
            .frame(height: 140)
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
                        .foregroundStyle(.white)

                    Text("\(self.cityCount) cities worldwide")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
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
