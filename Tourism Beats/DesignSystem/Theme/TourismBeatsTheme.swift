// TourismBeatsTheme.swift
// Tourism Beats
//
// A centralized theme providing convenience access to all design tokens.
// Use this as the single discovery point for the entire design system.

import SwiftUI

/// The centralized theme for Tourism Beats, providing access to all design tokens.
///
/// Use `TourismBeatsTheme` as the single entry point for colors, typography,
/// spacing, and animation values throughout the app.
///
/// ```swift
/// Text("Hello")
///     .font(TourismBeatsTheme.Typography.songTitle)
///     .padding(TourismBeatsTheme.Spacing.medium)
/// ```
enum TourismBeatsTheme {
    /// Color tokens — brand, semantic, surface, glass, and label colors.
    typealias Colors = AppColors

    /// Typography tokens — semantic Dynamic Type font styles.
    typealias Typography = TypographyTokens

    /// Spacing tokens — 4pt grid system for padding and margins.
    typealias Spacing = SpacingTokens

    /// Animation tokens — consistent motion curves and durations.
    typealias Animations = AnimationTokens
}
