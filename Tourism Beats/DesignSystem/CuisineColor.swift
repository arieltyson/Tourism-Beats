import SwiftUI

// MARK: - CuisineColor

/// Maps cuisine strings to coherent color categories from the app's design system.
/// Cuisines are grouped into cultural/regional families, each with a distinct color
/// that maintains WCAG AA contrast in both light and dark modes.
enum CuisineColor {
    /// Returns the badge color for a cuisine display string (e.g. "Japanese", "Italian • French").
    /// Uses the first cuisine token when multiple are present.
    static func color(for cuisineString: String?) -> Color {
        guard let cuisineString, !cuisineString.isEmpty else {
            return self.defaultColor
        }

        let primary = cuisineString
            .components(separatedBy: "\u{2022}")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            ?? cuisineString.lowercased()

        return Self.cuisineColorMap[primary] ?? Self.inferColor(from: primary)
    }

    /// Returns a lighter tint suitable for badge backgrounds (20% opacity of the cuisine color).
    static func badgeBackground(for cuisineString: String?) -> Color {
        self.color(for: cuisineString).opacity(0.18)
    }

    // MARK: - Color Palette

    /// Warm amber — East Asian cuisines (Japanese, Chinese, Korean, etc.)
    private static let eastAsian = AppColors.gold

    /// Coral-red — Southeast Asian (Thai, Vietnamese) and Indian subcontinent
    private static let southAsian = AppColors.coral

    /// Deep blue — Western European (French, Italian, Spanish, etc.)
    private static let european = AppColors.info

    /// Teal-green — Mediterranean, Turkish, Middle Eastern
    private static let mediterranean = AppColors.safe

    /// Vibrant magenta — Latin American (Mexican, Brazilian, Peruvian, Caribbean)
    private static let latinAmerican = AppColors.magenta

    /// Violet — American, Burgers, Steakhouse, BBQ
    private static let american = AppColors.violet

    /// Warm gold — Bakery, Cafe, Dessert
    private static let bakeryAndCafe = AppColors.gold

    /// Teal — Seafood
    private static let seafood = AppColors.safe

    /// Default neutral for unknown cuisines
    private static let defaultColor = AppColors.info

    // MARK: - Mapping

    private static let cuisineColorMap: [String: Color] = [
        // East Asian
        "japanese": eastAsian,
        "chinese": eastAsian,
        "korean": eastAsian,
        "sushi": eastAsian,
        "ramen": eastAsian,
        "dim sum": eastAsian,
        "taiwanese": eastAsian,
        "cantonese": eastAsian,
        "szechuan": eastAsian,
        "asian": eastAsian,

        // South & Southeast Asian
        "thai": southAsian,
        "vietnamese": southAsian,
        "indian": southAsian,
        "ethiopian": southAsian,
        "indonesian": southAsian,
        "malaysian": southAsian,
        "filipino": southAsian,
        "burmese": southAsian,
        "nepali": southAsian,
        "sri lankan": southAsian,
        "pakistani": southAsian,
        "bangladeshi": southAsian,
        "cambodian": southAsian,
        "laotian": southAsian,

        // Western European
        "french": european,
        "italian": european,
        "spanish": european,
        "german": european,
        "english": european,
        "portuguese": european,
        "greek": european,
        "russian": european,
        "irish": european,
        "scottish": european,
        "swiss": european,
        "austrian": european,
        "belgian": european,
        "dutch": european,
        "scandinavian": european,
        "polish": european,
        "hungarian": european,
        "czech": european,
        "european": european,

        // Mediterranean & Middle Eastern
        "mediterranean": mediterranean,
        "turkish": mediterranean,
        "lebanese": mediterranean,
        "middle eastern": mediterranean,
        "persian": mediterranean,
        "moroccan": mediterranean,
        "arab": mediterranean,
        "israeli": mediterranean,
        "afghan": mediterranean,
        "egyptian": mediterranean,
        "syrian": mediterranean,
        "georgian": mediterranean,

        // Latin American
        "mexican": latinAmerican,
        "brazilian": latinAmerican,
        "peruvian": latinAmerican,
        "caribbean": latinAmerican,
        "cuban": latinAmerican,
        "colombian": latinAmerican,
        "argentinian": latinAmerican,
        "venezuelan": latinAmerican,
        "chilean": latinAmerican,
        "puerto rican": latinAmerican,
        "latin american": latinAmerican,

        // American
        "american": american,
        "burgers": american,
        "steakhouse": american,
        "bbq": american,
        "barbecue": american,
        "cajun": american,
        "southern": american,
        "tex-mex": american,
        "hawaiian": american,
        "diner": american,

        // Seafood
        "seafood": seafood,
        "fish": seafood,
        "fish and chips": seafood,
        "oyster": seafood,
        "ceviche": seafood,

        // Bakery & Cafe
        "bakery": bakeryAndCafe,
        "cafe": bakeryAndCafe,
        "dessert": bakeryAndCafe,
        "pastry": bakeryAndCafe,
        "patisserie": bakeryAndCafe,
        "ice cream": bakeryAndCafe,

        // Special categories
        "pizza": european,
        "pasta": european,
        "tapas": european,
        "fusion": defaultColor,
        "international": defaultColor,
        "other": defaultColor,
        "fast food": defaultColor,
        "snack": defaultColor,
        "vegan": mediterranean,
        "vegetarian": mediterranean
    ]

    /// Attempts to infer a color for unmapped cuisine strings by keyword matching.
    private static func inferColor(from cuisine: String) -> Color {
        if cuisine.localizedStandardContains("asian")
            || cuisine.localizedStandardContains("noodle")
            || cuisine.localizedStandardContains("wok")
        {
            return self.eastAsian
        }
        if cuisine.localizedStandardContains("grill")
            || cuisine.localizedStandardContains("steak")
            || cuisine.localizedStandardContains("burger")
        {
            return self.american
        }
        if cuisine.localizedStandardContains("sea")
            || cuisine.localizedStandardContains("fish")
        {
            return self.seafood
        }
        if cuisine.localizedStandardContains("cafe")
            || cuisine.localizedStandardContains("bakery")
            || cuisine.localizedStandardContains("coffee")
        {
            return self.bakeryAndCafe
        }
        return self.defaultColor
    }
}
