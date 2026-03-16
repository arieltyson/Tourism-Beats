// TypographyTokens.swift
// Tourism Beats
//
// Typography scale built entirely on Dynamic Type.
// Never use hard-coded font sizes; these tokens scale
// automatically with the user's accessibility settings.

import SwiftUI

/// Typography tokens providing semantic text styles for Tourism Beats.
///
/// Every token maps to a Dynamic Type style, ensuring the app
/// remains fully readable at all accessibility text sizes.
enum TypographyTokens {
    /// Large hero titles — city name headers, launch titles.
    static let heroTitle: Font = .largeTitle

    /// Section headers — card titles, group labels.
    static let sectionHeader: Font = .headline

    /// Song titles and prominent card labels.
    static let songTitle: Font = .title3

    /// Card labels — provider names, weather condition text.
    static let cardLabel: Font = .subheadline

    /// Body text — descriptions, advisory content.
    static let body: Font = .body

    /// Artist names and secondary information within cards.
    static let artistName: Font = .subheadline

    /// Secondary text — timestamps, metadata, digital clock.
    static let caption: Font = .caption

    /// Footnote text — legal attributions, WeatherKit branding.
    static let footnote: Font = .caption2
}
