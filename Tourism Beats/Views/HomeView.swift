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
                if self.viewModel.isLoaded {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        HomeFeaturedCitiesCarousel(
                            items: self.viewModel.items,
                            initialItemID: self.viewModel.initialItemID,
                            scheme: self.scheme,
                            localTime: { city in
                                self.viewModel.localTime(for: city)
                            },
                            onCardAppear: { item in
                                self.viewModel.cardDidAppear(item)
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
                DiscoveryCTACard(scheme: self.scheme) {
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
                    count: self.viewModel.featuredCityCount
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

/// An endless row of city cards that snaps one card at a time. Cards sit side
/// by side and never overlap; as one leaves the centre it eases back, dims,
/// and turns slightly away, so the motion follows the finger without flipping.
private struct HomeFeaturedCitiesCarousel: View {
    let items: [HomeCarouselItem]
    let scheme: ColorScheme
    let localTime: (CityModel) -> String
    let onCardAppear: (HomeCarouselItem) -> Void
    let onSelectCity: (CityModel) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var centeredItemID: HomeCarouselItem.ID?

    /// How far the neighbouring cards show past the centred one.
    private static let peekInset = SpacingTokens.xxLarge + SpacingTokens.large
    /// How much smaller, dimmer, and turned a card is one position from centre.
    private static let neighbourScaleReduction = 0.1
    private static let neighbourOpacityReduction = 0.45
    private static let neighbourTiltDegrees = 12.0
    private static let tiltPerspective = 0.5

    init(
        items: [HomeCarouselItem],
        initialItemID: HomeCarouselItem.ID?,
        scheme: ColorScheme,
        localTime: @escaping (CityModel) -> String,
        onCardAppear: @escaping (HomeCarouselItem) -> Void,
        onSelectCity: @escaping (CityModel) -> Void
    ) {
        self.items = items
        self.scheme = scheme
        self.localTime = localTime
        self.onCardAppear = onCardAppear
        self.onSelectCity = onSelectCity
        self._centeredItemID = State(initialValue: initialItemID)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: SpacingTokens.small) {
                ForEach(self.items) { item in
                    DiscoveryCityCard(
                        city: item.city,
                        localTime: self.localTime(item.city),
                        scheme: self.scheme
                    ) {
                        self.onSelectCity(item.city)
                    }
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        let distance = min(abs(phase.value), 1)
                        return content
                            .scaleEffect(1 - distance * Self.neighbourScaleReduction)
                            .opacity(1 - distance * Self.neighbourOpacityReduction)
                            .rotation3DEffect(
                                .degrees(self.reduceMotion ? 0 : -phase.value * Self.neighbourTiltDegrees),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: Self.tiltPerspective
                            )
                    }
                    .onAppear {
                        self.onCardAppear(item)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: self.$centeredItemID, anchor: .center)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .safeAreaPadding(.horizontal, Self.peekInset)
        // A horizontal scroll view takes all the height it's offered; keep it
        // to the cards' own height so the header and carousel stay centred.
        .fixedSize(horizontal: false, vertical: true)
        .sensoryFeedback(.selection, trigger: self.centeredItemID)
        .accessibilityLabel("Featured cities")
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
                // Color.clear sets the bounds so a wide fill-scaled image can't widen the card.
                Color.clear
                    .frame(height: self.cardHeight)
                    .overlay {
                        CachedCityImage(url: self.city.imageURL, fallbackCoordinate: self.city.coordinate)
                    }
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
        .buttonStyle(.cardPress)
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
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text("Explore all destinations")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppColors.onImagePrimary)

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
        .buttonStyle(.cardPress)
        .accessibilityLabel("Explore all destinations")
        .accessibilityHint("Opens the search tab to explore destinations")
    }
}
