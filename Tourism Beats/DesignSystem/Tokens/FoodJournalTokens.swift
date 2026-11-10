import SwiftUI

/// Sizes for the Food Journal's cards.
enum FoodJournalTokens {
    static let cardCornerRadius: CGFloat = 20
    /// The world's best cuisine leads at full width; the rest share rows.
    static let leadingCuisineCardHeight: CGFloat = 220
    static let cuisineCardHeight: CGFloat = 150
    /// Cuisine cards per row below the leading one.
    static let cuisineColumns = 2
    /// Gastro cities are a longer list, so each is a slim banner.
    static let gastroCardHeight: CGFloat = 88
    static let gastroCardCornerRadius: CGFloat = 16
    /// Wide enough that a banner never truncates a city; wider screens
    /// fit two or more side by side.
    static let gastroCardMinimumWidth: CGFloat = 300
    /// Keeps one- and two-digit ranks aligned down the list.
    static let gastroRankWidth: CGFloat = 32
    /// One width for every distinction symbol, so the facts align.
    static let gastroDistinctionIconWidth: CGFloat = 16
}
