import SwiftUI

/// Sizes for the Food Journal's cards.
enum FoodJournalTokens {
    static let cardCornerRadius: CGFloat = 20
    /// The world's best cuisine leads at full width; the rest share rows.
    static let leadingCuisineCardHeight: CGFloat = 220
    static let cuisineCardHeight: CGFloat = 150
    /// Cuisine cards per row below the leading one.
    static let cuisineColumns = 2
}
