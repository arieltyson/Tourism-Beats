import SwiftUI

/// Translucent, animated "liquid glass" capsule that hugs the bottom safe area.
struct LiquidTabBarBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let bottom = max(proxy.safeAreaInsets.bottom, 6)
            let height: CGFloat = 58 + bottom

            ZStack {
                // Base glass
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Animated caustics
                if !reduceMotion {
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        Canvas { ctx, size in
                            func bubble(
                                _ x: CGFloat,
                                _ y: CGFloat,
                                r: CGFloat,
                                phase: Double,
                                strength: CGFloat = 0.28
                            ) {
                                let px = x + CGFloat(sin(phase)) * 10
                                let py = y + CGFloat(cos(phase * 0.9)) * 6
                                let rect = CGRect(
                                    x: px - r,
                                    y: py - r,
                                    width: r * 2,
                                    height: r * 2
                                )
                                let gradient = Gradient(colors: [
                                    .white.opacity(Double(strength)),
                                    .white.opacity(Double(strength * 0.10)),
                                    .clear,
                                ])
                                ctx.fill(
                                    Path(ellipseIn: rect),
                                    with: .radialGradient(
                                        gradient,
                                        center: CGPoint(x: px, y: py),
                                        startRadius: 0,
                                        endRadius: r
                                    )
                                )
                            }
                            bubble(
                                size.width * 0.22,
                                size.height * 0.25,
                                r: 120,
                                phase: t * 0.7
                            )
                            bubble(
                                size.width * 0.78,
                                size.height * 0.30,
                                r: 140,
                                phase: t * 0.9
                            )
                            bubble(
                                size.width * 0.50,
                                size.height * 0.85,
                                r: 180,
                                phase: t * 0.55,
                                strength: 0.20
                            )
                        }
                    }
                    .allowsHitTesting(false)
                    .blendMode(.plusLighter)
                }

                // Edge + shadow
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        .white.opacity(scheme == .dark ? 0.12 : 0.18),
                        lineWidth: 1
                    )
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.bottom, max(bottom - 4, 0))
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.35 : 0.18),
                radius: 18,
                y: -2
            )
            .compositingGroup()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
