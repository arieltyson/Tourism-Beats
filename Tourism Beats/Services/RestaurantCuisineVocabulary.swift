import Foundation

// MARK: - RestaurantCuisineVocabulary

/// The concise cuisine labels restaurant guides use, and how raw cuisine
/// values from OpenStreetMap and elsewhere map onto them.
///
/// Every restaurant gets at most one short label, such as "Italian" or
/// "Coffee", so a list can be read at a glance.
enum RestaurantCuisineVocabulary {
    /// Every label a restaurant can be given, alphabetized.
    static let labels: [String] = Array(Set(Self.labelsByTerm.values))
        .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    /// The label for a raw cuisine value such as "italian;pizza",
    /// "coffee_shop", or "Italian • Pizza".
    ///
    /// The first informative term wins. Terms that say nothing about the food,
    /// such as "regional" or "fine_dining", are skipped, and unfamiliar terms
    /// are title-cased so a specific local cuisine ("Creole") still shows.
    static func label(for rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        let terms = rawValue
            .split { $0 == ";" || $0 == "," || $0 == "•" || $0 == "/" }
            .map(Self.normalizedTerm)
            .filter { !$0.isEmpty && !Self.uninformativeTerms.contains($0) }

        guard let first = terms.first else { return nil }

        if let known = terms.lazy.compactMap({ Self.labelsByTerm[$0] }).first {
            return known
        }

        return first
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    // MARK: - Terms

    private static func normalizedTerm(_ term: Substring) -> String {
        String(term)
            .replacing("_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// Terms describing the setting rather than the food.
    private static let uninformativeTerms: Set<String> = [
        "restaurant", "food", "fine dining", "regional", "local", "yes", "casual",
        "contemporary", "modern", "traditional", "family", "buffet"
    ]

    private static let labelsByTerm: [String: String] = [
        // Drinks
        "coffee": "Coffee", "coffee shop": "Coffee", "espresso": "Coffee",
        "cafe": "Cafe", "café": "Cafe",
        "tea": "Tea", "tea house": "Tea", "matcha": "Tea",
        "bubble tea": "Bubble Tea", "boba": "Bubble Tea",
        "juice": "Juice", "smoothie": "Juice",
        "wine": "Wine Bar", "wine bar": "Wine Bar",
        "bar": "Bar", "pub": "Bar", "cocktail": "Bar", "beer": "Bar", "brewery": "Bar",

        // Sweets
        "bakery": "Bakery", "pastry": "Bakery", "patisserie": "Bakery", "bagel": "Bakery",
        "dessert": "Dessert", "ice cream": "Dessert", "gelato": "Dessert",
        "donut": "Dessert", "crepe": "Dessert", "chocolate": "Dessert",

        // Dishes and styles
        "breakfast": "Breakfast", "brunch": "Brunch",
        "burger": "Burgers", "burgers": "Burgers",
        "pizza": "Pizza",
        "steak house": "Steakhouse", "steakhouse": "Steakhouse", "steak": "Steakhouse",
        "barbecue": "Barbecue", "bbq": "Barbecue",
        "seafood": "Seafood", "fish": "Seafood", "fish and chips": "Seafood", "oyster": "Seafood",
        "sushi": "Sushi", "ramen": "Ramen", "noodle": "Noodles", "noodles": "Noodles",
        "dim sum": "Dim Sum", "dumpling": "Dim Sum",
        "tapas": "Tapas",
        "sandwich": "Sandwiches", "deli": "Sandwiches",
        "chicken": "Chicken", "fried chicken": "Chicken",
        "kebab": "Middle Eastern", "falafel": "Middle Eastern",
        "vegan": "Vegan", "vegetarian": "Vegetarian",
        "fusion": "Fusion", "international": "International",

        // Regions
        "american": "American", "diner": "American", "californian": "Californian", "southern": "Southern",
        "mexican": "Mexican", "tex-mex": "Mexican", "taco": "Mexican",
        "caribbean": "Caribbean", "jamaican": "Caribbean", "cuban": "Caribbean",
        "brazilian": "Brazilian", "peruvian": "Peruvian", "argentinian": "Argentinian",
        "latin american": "Latin American", "colombian": "Latin American",
        "italian": "Italian", "french": "French", "spanish": "Spanish",
        "portuguese": "Portuguese", "greek": "Greek", "german": "German",
        "british": "British", "english": "British", "irish": "Irish",
        "mediterranean": "Mediterranean", "turkish": "Turkish",
        "lebanese": "Lebanese", "middle eastern": "Middle Eastern", "persian": "Persian",
        "moroccan": "Moroccan", "ethiopian": "Ethiopian", "african": "African",
        "indian": "Indian", "pakistani": "Indian", "nepalese": "Nepalese",
        "chinese": "Chinese", "cantonese": "Chinese", "sichuan": "Chinese",
        "japanese": "Japanese", "korean": "Korean", "thai": "Thai",
        "vietnamese": "Vietnamese", "filipino": "Filipino", "malaysian": "Malaysian",
        "indonesian": "Indonesian", "asian": "Asian",
        "russian": "Russian", "georgian": "Georgian", "polish": "Polish",
        "scandinavian": "Nordic", "nordic": "Nordic", "hawaiian": "Hawaiian"
    ]
}
