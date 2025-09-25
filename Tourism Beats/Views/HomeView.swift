import SwiftUI

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    // Measured sizes
    @State private var subtitleSize: CGSize = .zero

    var body: some View {
        ZStack {
            EarthView()
                .ignoresSafeArea()

            // Readability vignette
            RadialGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.32),
                    Color.black.opacity(0.55),
                ],
                center: .center,
                startRadius: 60,
                endRadius: 520
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                // Ensure we never pass a negative available width downstream
                let safeWidth = max(0, proxy.size.width - horizontalPadding * 2)

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    // Title & subtitle
                    VStack(spacing: 10) {
                        Text("Tourism Beats")
                            .font(
                                .system(.largeTitle, design: .rounded).weight(
                                    .black
                                )
                            )
                            .kerning(0.5)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .shadow(
                                color: .black.opacity(0.35),
                                radius: 8,
                                y: 2
                            )
                            .accessibilityAddTraits(.isHeader)

                        Text("an immersive tourist experience")
                            .font(.system(.title3, design: .rounded).italic())
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .shadow(
                                color: .black.opacity(0.25),
                                radius: 6,
                                y: 1
                            )
                            .measureSize { size in
                                // Update only on meaningful change to avoid thrash
                                if abs(size.width - subtitleSize.width) > 0.5
                                    || abs(size.height - subtitleSize.height)
                                        > 0.5
                                {
                                    subtitleSize = size
                                }
                            }
                    }
                    .padding(.horizontal, horizontalPadding)

                    // CTA — width matches subtitle when possible, otherwise expands to fit text
                    GlassCTA(
                        title: "Explore destinations",
                        subtitle: "Tap the Search icon below",
                        matchToWidth: subtitleSize.width,
                        maxAvailableWidth: safeWidth
                    )
                    .padding(.horizontal, horizontalPadding)
                    .accessibilityHint(
                        "Tap the Search tab below to begin exploring."
                    )

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var horizontalPadding: CGFloat {
        switch typeSize {
        case ...DynamicTypeSize.xxxLarge: 24
        default: 20
        }
    }
}

// MARK: - Glass CTA that sizes to its own text (with subtitle-width matching)

private struct GlassCTA: View {
    let title: String
    let subtitle: String
    let matchToWidth: CGFloat  // measured width of the subtitle above
    let maxAvailableWidth: CGFloat  // container width minus outer padding

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Internals
    @State private var titleSize: CGSize = .zero
    @State private var subtitleSize: CGSize = .zero

    private let innerHPad: CGFloat = 18
    private let innerVPad: CGFloat = 14
    private let iconWidth: CGFloat = 28
    private let hSpacing: CGFloat = 12
    private let minReadable: CGFloat = 220  // floor so it never looks cramped

    var body: some View {
        // Measure intrinsic widths of the two text lines (invisibly)
        ZStack {
            content
            measuringOverlay
        }
        .allowsHitTesting(false)  // CTA instructs; not tappable
    }

    private var content: some View {
        // Calculate the text block width we actually need
        let neededTextWidth = max(
            titleSize.width.isFinite ? titleSize.width : 0,
            subtitleSize.width.isFinite ? subtitleSize.width : 0
        )

        // Proposed content width: match subtitle above, but never less than what we need
        let safeMatchWidth = matchToWidth.isFinite ? max(0, matchToWidth) : 0
        var contentWidth = max(safeMatchWidth, neededTextWidth)

        // Add space for the trailing icon + spacing
        contentWidth += (hSpacing + iconWidth)

        // Clamp to available space and ensure a minimum readable width
        let available = max(0, maxAvailableWidth.isFinite ? maxAvailableWidth : 0)
        if available > 0 {
            contentWidth = min(max(contentWidth, minReadable), available)
        } else {
            // No available width reported yet; still ensure we never pass a negative/non-finite value
            contentWidth = max(contentWidth, minReadable)
        }

        // Final sanitization: only pass a valid width to .frame; otherwise let SwiftUI size it
        let frameWidth: CGFloat? = (contentWidth.isFinite && contentWidth > 0) ? contentWidth : nil

        return HStack(spacing: hSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 0)

            AnimatedSearchIcon(reduceMotion: reduceMotion)
                .frame(width: iconWidth, height: iconWidth)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, innerHPad)
        .padding(.vertical, innerVPad)
        .frame(width: frameWidth)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            .white.opacity(scheme == .dark ? 0.12 : 0.18),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.35 : 0.18),
                    radius: 18,
                    y: 6
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle).")
    }

    // Invisible measurement so we can size precisely without truncation
    private var measuringOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .fixedSize()  // measure intrinsic single-line width
                .measureSize { titleSize = $0 }

            Text(subtitle)
                .font(.footnote)
                .fixedSize()
                .measureSize { subtitleSize = $0 }
        }
        .opacity(0.001)  // effectively invisible but doesn’t collapse
        .allowsHitTesting(false)
    }
}

// MARK: - Animated Search Icon (calm / natural pacing)

private struct AnimatedSearchIcon: View {
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)

            if !reduceMotion {
                // Slow breathe (~9s)
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let scale = 1.0 + 0.03 * CGFloat(sin(t * 0.7))
                    Image(systemName: "magnifyingglass.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white.opacity(0.95))
                        .scaleEffect(scale)
                        .allowsHitTesting(false)
                }

                // Subtle ping (~3.6s per ring, staggered)
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

// MARK: - Size measuring helper

private struct ViewSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    fileprivate func measureSize(_ onChange: @escaping (CGSize) -> Void)
        -> some View
    {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(ViewSizeKey.self, perform: onChange)
    }
}
