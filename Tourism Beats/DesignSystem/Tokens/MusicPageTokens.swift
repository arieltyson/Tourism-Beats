// MusicPageTokens.swift
// Tourism Beats
//
// Sizing for the Top Songs page of the city pager.

import CoreGraphics

/// Design tokens for the Top Songs page.
enum MusicPageTokens {
    /// The largest side the album artwork reaches, on any screen.
    static let artworkMaximumSide: CGFloat = 320

    /// The smallest side the artwork shrinks to so the page fits the pager.
    ///
    /// The page scrolls only when it can't fit even with the artwork this small.
    /// At this size the artwork still reads as the page's hero, and a compact
    /// iPhone fits the page at the default text size.
    static let artworkMinimumSide: CGFloat = 128
}
