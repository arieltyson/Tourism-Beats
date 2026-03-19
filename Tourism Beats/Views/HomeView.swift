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
    let localTime: (CityModel) -> String
    let onSelectCity: (CityModel) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var ringPosition: CGFloat = 0
    @State private var dragBasePosition: CGFloat = 0
    @State private var isDragging = false

    private static let cardWidth: CGFloat = 220
    private static let peekSpacing: CGFloat = 130

    private var cardHeight: CGFloat {
        self.dynamicTypeSize.isAccessibilitySize ? 168 : 140
    }

    var body: some View {
        let count = self.featuredCities.count
        let countF = CGFloat(count)

        ZStack {
            ForEach(
                Array(self.featuredCities.enumerated()),
                id: \.element.id
            ) { index, city in
                let fractional = Self.wrappedOffset(
                    CGFloat(index) - self.ringPosition,
                    count: countF
                )

                if abs(fractional) < 3.5 {
                    self.positionedCard(
                        city: city, fractionalOffset: fractional
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight + 16)
        .contentShape(.rect)
        .highPriorityGesture(self.ringDragGesture(count: countF))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Featured cities carousel")
    }

    // MARK: - Card Positioning

    @ViewBuilder
    private func positionedCard(
        city: CityModel,
        fractionalOffset: CGFloat
    ) -> some View {
        let absOffset = abs(fractionalOffset)
        let scale = max(0.65, 1.0 - absOffset * 0.12)
        let xPosition = fractionalOffset * Self.peekSpacing
        let yRotation = self.reduceMotion ? 0 : -fractionalOffset * 22
        let cardOpacity = max(0.0, 1.0 - absOffset * 0.35)
        let depth = 100.0 - absOffset

        DiscoveryCityCard(
            city: city,
            localTime: self.localTime(city),
            scheme: self.scheme
        ) {
            self.onSelectCity(city)
        }
        .frame(width: Self.cardWidth, height: self.cardHeight)
        .scaleEffect(scale)
        .offset(x: xPosition)
        .rotation3DEffect(
            .degrees(yRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .opacity(cardOpacity)
        .zIndex(depth)
        .allowsHitTesting(!self.isDragging && absOffset < 0.5)
    }

    // MARK: - Ring Math

    private static func wrappedOffset(
        _ offset: CGFloat,
        count: CGFloat
    ) -> CGFloat {
        guard count > 0 else { return offset }
        var wrapped = offset.truncatingRemainder(dividingBy: count)
        if wrapped > count / 2 { wrapped -= count }
        if wrapped < -count / 2 { wrapped += count }
        return wrapped
    }

    // MARK: - Gesture

    private func ringDragGesture(count _: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                if !self.isDragging {
                    self.isDragging = true
                    self.dragBasePosition = self.ringPosition
                }
                self.ringPosition = self.dragBasePosition
                    - value.translation.width / Self.cardWidth
            }
            .onEnded { value in
                self.isDragging = false

                let velocity = -(
                    value.predictedEndTranslation.width
                        - value.translation.width
                ) / Self.cardWidth
                let projected = self.ringPosition + velocity * 0.3
                let snapped = projected.rounded()

                withAnimation(
                    .spring(response: 0.45, dampingFraction: 0.82)
                ) {
                    self.ringPosition = snapped
                }
                self.dragBasePosition = snapped
            }
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
