import SwiftUI

/// Design tokens for the vertical page indicator strip.
///
/// Centralises all sizing, opacity, and layout values so the
/// indicator stays visually consistent and easy to tune.
enum PageIndicatorTokens {
    // MARK: - Sizing

    /// Icon hit-target for the modern (iOS 26+) variant.
    static let modernButtonSize: CGFloat = 28

    /// Capsule width for the legacy selection highlight.
    static let legacyCapsuleWidth: CGFloat = 32

    /// Capsule height for the legacy selection highlight.
    static let legacyCapsuleHeight: CGFloat = 40

    // MARK: - Spacing

    /// Vertical gap between icon buttons.
    static let buttonSpacing: CGFloat = 6

    /// Inner spacing of the glass effect container (iOS 26+).
    static let containerSpacing: CGFloat = 8

    // MARK: - Opacity

    /// Opacity for the currently selected icon.
    static let activeOpacity: Double = 1

    /// Opacity for unselected icons.
    static let inactiveOpacity: Double = 0.5

    // MARK: - Scale

    /// Scale factor applied to inactive legacy buttons.
    static let inactiveScale: CGFloat = 0.88

    // MARK: - Border & Shadow (Legacy)

    /// Stroke width for the legacy capsule highlight border.
    static let legacyBorderWidth: CGFloat = 0.5

    /// Shadow blur radius for the legacy capsule highlight.
    static let legacyShadowRadius: CGFloat = 6

    /// Vertical shadow offset for the legacy capsule highlight.
    static let legacyShadowY: CGFloat = 2

    // MARK: - Overlay Position

    /// Trailing padding for the indicator overlay in its container.
    /// Negative to tuck the strip against the screen edge.
    static let overlayTrailingPadding: CGFloat = -2
}
