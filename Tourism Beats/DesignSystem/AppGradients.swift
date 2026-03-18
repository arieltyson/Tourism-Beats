import SwiftUI

/// Reusable gradient styles for the app shell and branded surfaces.
///
/// ``launch`` and ``launchRing`` power the branded launch animation.
/// ``vignette`` provides readability over full-bleed imagery.
/// Glass helpers centralise the material + stroke + shadow pattern used
/// throughout cards, indicators, and CTAs.
enum AppGradients {
    // MARK: - Launch

    /// Deep-space radial gradient used as the launch animation backdrop.
    ///
    /// A subtle luminous bloom radiates from the center — warm violet
    /// undertones transition through the brand's deep navy, grounding
    /// the splash screen in the same cosmic aesthetic as the home globe.
    static let launch = RadialGradient(
        colors: [
            Color(red: 0.14, green: 0.10, blue: 0.26),
            Color(red: 0.09, green: 0.08, blue: 0.20),
            Color(red: 0.05, green: 0.06, blue: 0.15),
            Color(red: 0.03, green: 0.04, blue: 0.10)
        ],
        center: .center,
        startRadius: 0,
        endRadius: 520
    )

    /// Cool luminous ring gradient for the launch progress indicator.
    static let launchRing = AngularGradient(
        colors: [
            AppColors.onImagePrimary.opacity(0.92),
            AppColors.info,
            AppColors.violet.opacity(0.78),
            AppColors.onImagePrimary.opacity(0.92)
        ],
        center: .center
    )

    // MARK: - Readability

    /// Radial vignette that improves text legibility over full-bleed imagery.
    static let vignette = RadialGradient(
        colors: [
            Color.black.opacity(0.08),
            Color.black.opacity(0.32),
            Color.black.opacity(0.55)
        ],
        center: .center,
        startRadius: 60,
        endRadius: 520
    )

    // MARK: - Scheme-Aware

    /// Hero card gradient for advisory or detail headers.
    ///
    /// Light mode uses soft coral → gold. Dark mode deepens to maintain
    /// contrast for white text.
    static func hero(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.52, green: 0.16, blue: 0.12),
                    Color(red: 0.42, green: 0.12, blue: 0.30)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            LinearGradient(
                colors: [AppColors.coral, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
