import SwiftUI

/// Reusable gradient styles for the app shell and branded surfaces.
///
/// ``launch`` and ``launchRing`` power the branded launch animation.
/// ``vignette`` provides readability over full-bleed imagery.
/// Glass helpers centralise the material + stroke + shadow pattern used
/// throughout cards, indicators, and CTAs.
enum AppGradients {
    // MARK: - Launch

    /// Diagonal warm gradient used as the launch animation backdrop.
    static let launch = LinearGradient(
        colors: [AppColors.coral, AppColors.magenta, AppColors.violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Angular ring gradient for the launch progress indicator.
    static let launchRing = AngularGradient(
        colors: [
            .white.opacity(0.9),
            AppColors.gold,
            AppColors.magenta,
            .white.opacity(0.9)
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
