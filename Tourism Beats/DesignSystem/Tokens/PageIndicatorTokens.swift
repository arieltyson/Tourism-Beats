import SwiftUI

/// Design tokens for the vertical page indicator strip.
///
/// Centralises all sizing, opacity, and layout values so the
/// indicator stays visually consistent and easy to tune.
enum PageIndicatorTokens {
    // MARK: - Modern Sizing (iOS 26+)

    /// Width of each icon button's tap target.
    static let modernButtonWidth: CGFloat = 36

    /// Height of each icon button's tap target — meets the 44pt HIG minimum.
    static let modernButtonHeight: CGFloat = 44

    /// Diameter of the circle highlight behind the active icon.
    static let modernHighlightSize: CGFloat = 28

    // MARK: - Legacy Sizing

    /// Capsule width for the legacy selection highlight.
    static let legacyCapsuleWidth: CGFloat = 36

    /// Capsule height for the legacy selection highlight.
    static let legacyCapsuleHeight: CGFloat = 44

    // MARK: - Spacing

    /// Vertical gap between icon buttons.
    static let buttonSpacing: CGFloat = 0

    /// Inner spacing of the glass effect container (iOS 26+).
    static let containerSpacing: CGFloat = 4

    // MARK: - Opacity

    /// Opacity for the currently selected icon.
    static let activeOpacity: Double = 1

    /// Opacity for unselected icons.
    static let inactiveOpacity: Double = 0.45

    // MARK: - Scale

    /// Scale factor applied to inactive legacy buttons.
    static let inactiveScale: CGFloat = 0.92

    // MARK: - Border & Shadow (Legacy)

    /// Stroke width for the legacy capsule highlight border.
    static let legacyBorderWidth: CGFloat = 0.5

    /// Shadow blur radius for the legacy capsule highlight.
    static let legacyShadowRadius: CGFloat = 6

    /// Vertical shadow offset for the legacy capsule highlight.
    static let legacyShadowY: CGFloat = 2

    // MARK: - Overlay Position

    /// Trailing padding for the indicator overlay from the screen edge.
    static let overlayTrailingPadding: CGFloat = 4

    // MARK: - Content Layout

    /// Symmetric horizontal padding applied to the content scroll view,
    /// creating equal space on both sides so page content is centered
    /// with the indicator occupying the trailing margin.
    static let contentInset: CGFloat = 20
}
