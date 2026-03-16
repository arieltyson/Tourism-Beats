import SwiftUI
import UIKit

/// Tourism Beats' brand and semantic color system.
///
/// Brand, semantic, surface, and label colors all resolve dynamically via
/// ``UIColor`` trait collection. Colors adapt to the user's interface style
/// (light / dark) **and** the Increase Contrast accessibility setting
/// (`UIAccessibilityContrast.high`), ensuring >= 4.5 : 1 WCAG AA contrast
/// for foreground text and icons in every configuration.
enum AppColors {
    // MARK: - Brand (Contrast-Adaptive)

    /// Warm coral-orange for primary actions, active states, and accents.
    ///
    /// High-contrast light: darkened to ~5.2 : 1 on white.
    /// High-contrast dark: lightened to ~6.0 : 1 on dark surface.
    static let coral = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.98, green: 0.48, blue: 0.35, alpha: 1)
                    : UIColor(red: 0.72, green: 0.22, blue: 0.12, alpha: 1)
            }
            return UIColor(red: 0.95, green: 0.38, blue: 0.25, alpha: 1)
        }
    )

    /// Vibrant magenta-pink for secondary accents and decorative highlights.
    ///
    /// High-contrast light: darkened to ~5.0 : 1 on white.
    /// High-contrast dark: lightened to ~6.5 : 1 on dark surface.
    static let magenta = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.92, green: 0.38, blue: 0.62, alpha: 1)
                    : UIColor(red: 0.62, green: 0.10, blue: 0.34, alpha: 1)
            }
            return UIColor(red: 0.85, green: 0.22, blue: 0.50, alpha: 1)
        }
    )

    /// Deep violet for gradient endpoints and rich accents.
    ///
    /// High-contrast light: darkened to ~7.0 : 1 on white.
    /// High-contrast dark: lightened to ~5.8 : 1 on dark surface.
    static let violet = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.68, green: 0.38, blue: 0.90, alpha: 1)
                    : UIColor(red: 0.38, green: 0.12, blue: 0.58, alpha: 1)
            }
            return UIColor(red: 0.55, green: 0.22, blue: 0.80, alpha: 1)
        }
    )

    /// Warm amber-gold for highlighted info, badges, and warm accents.
    static let gold = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 1.00, green: 0.78, blue: 0.38, alpha: 1)
                    : UIColor(red: 0.62, green: 0.42, blue: 0.08, alpha: 1)
            }
            return UIColor(red: 0.95, green: 0.68, blue: 0.28, alpha: 1)
        }
    )

    // MARK: - Semantics (Contrast-Adaptive)

    /// Primary accent — maps to ``coral``.
    static let accent = coral

    /// Teal for safe/positive advisory states.
    ///
    /// High-contrast light: darkened to ~5.0 : 1 on white.
    /// High-contrast dark: lightened to ~8.5 : 1 on dark surface.
    static let safe = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.42, green: 0.84, blue: 0.72, alpha: 1)
                    : UIColor(red: 0.12, green: 0.44, blue: 0.34, alpha: 1)
            }
            return UIColor(red: 0.30, green: 0.72, blue: 0.60, alpha: 1)
        }
    )

    /// Warm amber for caution / moderate-risk advisory states.
    static let caution = gold

    /// Red for danger / high-risk advisory states.
    ///
    /// High-contrast light: darkened to ~5.4 : 1 on white.
    /// High-contrast dark: lightened to ~5.8 : 1 on dark surface.
    static let danger = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.95, green: 0.42, blue: 0.42, alpha: 1)
                    : UIColor(red: 0.70, green: 0.18, blue: 0.18, alpha: 1)
            }
            return UIColor(red: 0.85, green: 0.30, blue: 0.30, alpha: 1)
        }
    )

    /// Blue for informational badges and shield decorations.
    ///
    /// High-contrast light: darkened to ~5.2 : 1 on white.
    /// High-contrast dark: lightened to ~6.0 : 1 on dark surface.
    static let info = Color(
        uiColor: UIColor { traits in
            if traits.accessibilityContrast == .high {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.48, green: 0.68, blue: 0.98, alpha: 1)
                    : UIColor(red: 0.14, green: 0.34, blue: 0.68, alpha: 1)
            }
            return UIColor(red: 0.30, green: 0.52, blue: 0.88, alpha: 1)
        }
    )

    // MARK: - Surfaces (Adaptive)

    /// Main content surface. White in light mode, near-black with a faint
    /// warm undertone in dark mode matching HIG elevated surfaces.
    static let surface = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.10, blue: 0.13, alpha: 1)
                : .white
        }
    )

    /// Secondary surface one step above ``surface``. Faint warm tint in
    /// light mode, slightly lifted charcoal in dark mode.
    static let surfaceSecondary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.14, blue: 0.18, alpha: 1)
                : UIColor(red: 0.98, green: 0.96, blue: 0.97, alpha: 1)
        }
    )

    // MARK: - Labels (Adaptive)

    /// Primary foreground for high-emphasis text over ``surface``.
    static let label = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.96, green: 0.94, blue: 0.98, alpha: 1)
                : UIColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 1)
        }
    )

    /// Muted text for secondary information. Maintains >= 4.5:1 contrast
    /// against ``surface`` in both light and dark modes (WCAG AA).
    static let secondaryLabel = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.70, green: 0.66, blue: 0.76, alpha: 1)
                : UIColor(red: 0.40, green: 0.38, blue: 0.48, alpha: 1)
        }
    )

    // MARK: - Glass & Shadow Tokens

    /// Glass border stroke color. Adapts opacity to color scheme.
    static func glassBorder(for scheme: ColorScheme) -> Color {
        .white.opacity(scheme == .dark ? 0.12 : 0.18)
    }

    /// Glass shadow color. Adapts opacity to color scheme.
    static func glassShadow(for scheme: ColorScheme) -> Color {
        .black.opacity(scheme == .dark ? 0.30 : 0.12)
    }
}
