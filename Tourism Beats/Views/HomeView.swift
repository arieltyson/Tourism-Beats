import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    let onExplore: () -> Void
    let onCitySelected: (CityModel) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var subtitleSize: CGSize = .zero
    @State private var featuredCities: [CityModel] = []
    @State private var haptic = HapticTrigger()

    var body: some View {
        ZStack {
            EarthView()
                .ignoresSafeArea()

            AppGradients.vignette
                .ignoresSafeArea()

            GeometryReader { proxy in
                let safeWidth = max(0, proxy.size.width - self.horizontalPadding * 2)

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    HeroTitle(subtitleSize: self.$subtitleSize)
                        .padding(.horizontal, self.horizontalPadding)

                    // Interactive CTA
                    ExploreCTA(
                        matchToWidth: self.subtitleSize.width,
                        maxAvailableWidth: safeWidth,
                        action: {
                            self.haptic.fire(.searchOpen)
                            self.onExplore()
                        }
                    )
                    .padding(.horizontal, self.horizontalPadding)

                    // Featured destination chips
                    if self.typeSize < .accessibility1,
                       !self.featuredCities.isEmpty
                    {
                        FeaturedCitiesRow(
                            cities: self.featuredCities,
                            onSelect: { city in
                                self.haptic.fire(.citySelect)
                                self.onCitySelected(city)
                            }
                        )
                        .padding(.horizontal, self.horizontalPadding)
                        .transition(.opacity)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.bottom, 16)
            }
        }
        .sensoryFeedback(self.haptic.feedback, trigger: self.haptic)
        .navigationBarBackButtonHidden(true)
        .task {
            guard self.featuredCities.isEmpty else { return }
            if let cities = try? DataService().loadCities() {
                self.featuredCities = Array(cities.shuffled().prefix(3))
            }
        }
    }

    private var horizontalPadding: CGFloat {
        switch self.typeSize {
        case ...DynamicTypeSize.xxxLarge: 24
        default: 20
        }
    }
}

// MARK: - HeroTitle

private struct HeroTitle: View {
    @Binding var subtitleSize: CGSize

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
                .measureSize { size in
                    if abs(size.width - self.subtitleSize.width) > 0.5
                        || abs(size.height - self.subtitleSize.height) > 0.5
                    {
                        self.subtitleSize = size
                    }
                }
        }
    }
}

// MARK: - ExploreCTA

private struct ExploreCTA: View {
    let matchToWidth: CGFloat
    let maxAvailableWidth: CGFloat
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var titleSize: CGSize = .zero
    @State private var subtitleSize: CGSize = .zero

    private let innerHPad: CGFloat = 18
    private let innerVPad: CGFloat = 14
    private let iconWidth: CGFloat = 28
    private let hSpacing: CGFloat = 12
    private let minReadable: CGFloat = 220

    var body: some View {
        Button(action: self.action) {
            ZStack {
                self.cardContent
                self.measuringOverlay
            }
        }
        .buttonStyle(GlassCTAButtonStyle(scheme: self.scheme))
        .accessibilityLabel("Explore destinations. Discover cities around the world.")
        .accessibilityHint("Opens the search tab to explore destinations")
    }

    private var cardContent: some View {
        let neededTextWidth = max(
            self.titleSize.width.isFinite ? self.titleSize.width : 0,
            self.subtitleSize.width.isFinite ? self.subtitleSize.width : 0
        )

        let safeMatchWidth = self.matchToWidth.isFinite ? max(0, self.matchToWidth) : 0
        var contentWidth = max(safeMatchWidth, neededTextWidth)
        contentWidth += (self.hSpacing + self.iconWidth)

        let available = max(0, self.maxAvailableWidth.isFinite ? self.maxAvailableWidth : 0)
        if available > 0 {
            contentWidth = min(max(contentWidth, self.minReadable), available)
        } else {
            contentWidth = max(contentWidth, self.minReadable)
        }

        let frameWidth: CGFloat? = (contentWidth.isFinite && contentWidth > 0) ? contentWidth : nil

        return HStack(spacing: self.hSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Explore destinations")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text("Discover cities around the world")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 0)

            AnimatedSearchIcon(reduceMotion: self.reduceMotion)
                .frame(width: self.iconWidth, height: self.iconWidth)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, self.innerHPad)
        .padding(.vertical, self.innerVPad)
        .frame(width: frameWidth)
    }

    private var measuringOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Explore destinations")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .fixedSize()
                .measureSize { self.titleSize = $0 }

            Text("Discover cities around the world")
                .font(.footnote)
                .fixedSize()
                .measureSize { self.subtitleSize = $0 }
        }
        .opacity(0.001)
        .allowsHitTesting(false)
    }
}

// MARK: - GlassCTAButtonStyle

private struct GlassCTAButtonStyle: ButtonStyle {
    let scheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - FeaturedCitiesRow

private struct FeaturedCitiesRow: View {
    let cities: [CityModel]
    let onSelect: (CityModel) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(self.cities) { city in
                    FeaturedCityChip(city: city) {
                        self.onSelect(city)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - FeaturedCityChip

private struct FeaturedCityChip: View {
    let city: CityModel
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 6) {
                Text(self.city.country.flag)
                    .font(.body)

                Text(self.city.name)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.city.country.flag) \(self.city.name), \(self.city.country.name)")
        .accessibilityHint("Opens city details")
    }
}

// MARK: - AnimatedSearchIcon

private struct AnimatedSearchIcon: View {
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)

            if !self.reduceMotion {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let scale = 1.0 + 0.03 * CGFloat(sin(t * 0.7))
                    Image(systemName: "magnifyingglass.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white.opacity(0.95))
                        .scaleEffect(scale)
                        .allowsHitTesting(false)
                }

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        func ring(_ phase: Double, alpha: Double) {
                            let p = CGFloat(
                                (t * 0.28 + phase).truncatingRemainder(
                                    dividingBy: 1
                                )
                            )
                            let scale = 1 + p * 0.55
                            let opacity = max(0, 1 - Double(p)) * alpha
                            let rect = CGRect(
                                x: size.width * (0.5 - 0.5 * scale),
                                y: size.height * (0.5 - 0.5 * scale),
                                width: size.width * scale,
                                height: size.height * scale
                            )
                            ctx.stroke(
                                Path(ellipseIn: rect),
                                with: .color(.white.opacity(opacity)),
                                lineWidth: 1
                            )
                        }
                        ring(0.00, alpha: 0.22)
                        ring(0.33, alpha: 0.18)
                        ring(0.66, alpha: 0.14)
                    }
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - ViewSizeKey

private struct ViewSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension View {
    func measureSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(ViewSizeKey.self, perform: onChange)
    }
}
