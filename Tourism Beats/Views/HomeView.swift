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
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        HomeFeaturedCitiesCarousel(
                            viewModel: self.viewModel,
                            date: context.date,
                            scheme: self.scheme,
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
        // The Earth behind this page is always at night, but the tab bar's
        // glass can't read a 3D scene the way it reads the map, so in Light
        // Mode it turned a flat gray with dark icons. It's dark glass here.
        .toolbarColorScheme(.dark, for: .tabBar)
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

/// An endless, overlapping row of city cards that turns in both directions.
///
/// The centre card sits in front; its neighbours tuck behind it, smaller,
/// dimmer, and turned so their inner edges lean back, which keeps them from
/// flaring over the centre as they move. Cards further out slide in behind
/// and fade, so a swipe never shows a card jumping or popping into place.
private struct HomeFeaturedCitiesCarousel: View {
    let viewModel: HomeViewModel
    /// The minute shown on each card's clock.
    let date: Date
    let scheme: ColorScheme
    let onSelectCity: (CityModel) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Where the carousel rests or is being dragged; a whole number puts that
    /// card in the centre.
    @State private var position: CGFloat = 0
    @State private var dragStartPosition: CGFloat?

    static let cardWidth: CGFloat = 220
    /// How far apart neighbouring cards sit, so each overlaps the next.
    private static let cardSpacing = cardWidth * 0.6
    /// How far a fling carries past where the finger lifted, in cards.
    private static let flingCarry: CGFloat = 0.25
    /// The most cards one fling moves.
    private static let maximumFlingDistance: CGFloat = 3

    private var centredPosition: Int {
        Int(self.position.rounded())
    }

    var body: some View {
        ZStack {
            ForEach(self.viewModel.visibleItems(around: self.position)) { item in
                let offset = CGFloat(item.id) - self.position

                HomeCarouselCard(
                    city: item.city,
                    localTime: self.viewModel.localTime(for: item.city, at: self.date),
                    scheme: self.scheme,
                    offset: offset,
                    cardSpacing: Self.cardSpacing,
                    tiltsWithDepth: !self.reduceMotion
                ) {
                    if item.id == self.centredPosition {
                        self.onSelectCity(item.city)
                    } else {
                        self.settle(at: CGFloat(item.id))
                    }
                }
                .frame(width: Self.cardWidth)
                .accessibilityHidden(item.id != self.centredPosition)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        self.settle(at: CGFloat(self.centredPosition + 1))
                    case .decrement:
                        self.settle(at: CGFloat(self.centredPosition - 1))
                    @unknown default:
                        break
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .highPriorityGesture(self.dragGesture)
        .onChange(of: self.centredPosition) { _, newPosition in
            self.viewModel.dealCities(around: newPosition)
        }
        .sensoryFeedback(.selection, trigger: self.centredPosition)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: SpacingTokens.medium)
            .onChanged { value in
                let start = self.dragStartPosition ?? self.position
                self.dragStartPosition = start
                self.position = start - value.translation.width / Self.cardSpacing
            }
            .onEnded { value in
                let start = self.dragStartPosition ?? self.position
                self.dragStartPosition = nil

                let projected = start - value.predictedEndTranslation.width / Self.cardSpacing
                let carried = self.position + (projected - self.position) * Self.flingCarry
                let target = min(
                    max(carried.rounded(), start.rounded() - Self.maximumFlingDistance),
                    start.rounded() + Self.maximumFlingDistance
                )
                self.settle(at: target)
            }
    }

    private func settle(at target: CGFloat) {
        withAnimation(AnimationTokens.carouselSettle) {
            self.position = target
        }
    }
}

// MARK: - HomeCarouselCard

/// A city card placed at `offset` cards from the carousel's centre.
private struct HomeCarouselCard: View {
    let city: CityModel
    let localTime: String
    let scheme: ColorScheme
    let offset: CGFloat
    let cardSpacing: CGFloat
    let tiltsWithDepth: Bool
    let action: () -> Void

    /// How much smaller, dimmer, and turned a card is one place from centre.
    private static let scaleStep = 0.12
    private static let dimmingStep = 0.12
    private static let tiltDegrees = 24.0
    private static let tiltPerspective = 0.45
    /// Beyond the nearest neighbours, cards tuck closer and fade away.
    private static let farSpacingRatio = 0.45

    var body: some View {
        let distance = abs(self.offset)
        let direction: CGFloat = self.offset < 0 ? -1 : 1
        let nearDistance = min(distance, 1)
        let farDistance = max(distance - 1, 0)

        DiscoveryCityCard(
            city: self.city,
            localTime: self.localTime,
            scheme: self.scheme,
            action: self.action
        )
        .brightness(-nearDistance * Self.dimmingStep)
        .scaleEffect(1 - min(distance, 2) * Self.scaleStep)
        .rotation3DEffect(
            // A neighbour turns with its inner edge leaning back, behind the centre card.
            .degrees(self.tiltsWithDepth ? -direction * nearDistance * Self.tiltDegrees : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: Self.tiltPerspective
        )
        .offset(x: direction * (nearDistance + farDistance * Self.farSpacingRatio) * self.cardSpacing)
        .opacity(1 - min(farDistance, 1))
        .zIndex(-Double(distance))
        .allowsHitTesting(distance < 1.5)
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
            .cardShadow(
                cornerRadius: 16,
                color: AppColors.glassShadow(for: self.scheme),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(.cardPress)
        .accessibilityLabel(
            "\(self.city.country.flag) \(self.city.name), \(self.city.locationName). Local time \(self.localTime)"
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
