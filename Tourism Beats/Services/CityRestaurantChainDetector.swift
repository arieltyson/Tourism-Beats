import Foundation

// MARK: - CityRestaurantChainDetector

/// Multi-layered chain and generic restaurant detection to ensure
/// unique, one-of-a-kind dining experiences in recommendations.
enum CityRestaurantChainDetector {
    /// Confidence level that a restaurant is a chain or generic establishment.
    enum ChainConfidence: Sendable, Comparable {
        /// Definitely not a chain (independent restaurant)
        case none

        /// Possibly generic or low-effort name
        case low

        /// Likely a chain or franchise
        case medium

        /// Confirmed chain (brand tag, known name, or multi-location)
        case high

        var penalty: Int {
            switch self {
            case .none: 0
            case .low: -3
            case .medium: -6
            case .high: -12
            }
        }
    }

    /// Evaluates chain/generic confidence for a candidate using all available signals.
    static func confidence(
        name: String,
        brand: String?,
        hasBrandWikidata: Bool,
        hasOperator: Bool,
        duplicateLocationCount: Int
    ) -> ChainConfidence {
        // Layer 1: OSM brand:wikidata confirms chain identity
        if hasBrandWikidata {
            return .high
        }

        let normalizedName = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Layer 2: Known chain exact match
        if self.knownChains.contains(normalizedName) {
            return .high
        }

        // Layer 3: Brand tag present with a known chain name
        if let brand {
            let normalizedBrand = brand
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if self.knownChains.contains(normalizedBrand) {
                return .high
            }
            // Any brand tag at all indicates franchise/chain
            if !normalizedBrand.isEmpty {
                return .medium
            }
        }

        // Layer 4: Multi-location detection (same name at 2+ coordinates)
        if duplicateLocationCount >= 2 {
            return .high
        }

        // Layer 5: Chain keyword containment (partial match)
        if self.chainKeywords.contains(where: { normalizedName.localizedStandardContains($0) }) {
            return .medium
        }

        // Layer 6: Operator tag indicates franchise management
        if hasOperator {
            return .low
        }

        // Layer 7: Generic name pattern detection
        if self.isGenericPattern(normalizedName) {
            return .low
        }

        return .none
    }
}

// MARK: - Generic Name Pattern Detection

extension CityRestaurantChainDetector {
    private static func isGenericPattern(_ normalizedName: String) -> Bool {
        // Exact generic names
        if self.genericExactNames.contains(normalizedName) {
            return true
        }

        // Hotel restaurant pattern: "hotel x restaurant", "restaurant at hotel"
        if normalizedName.localizedStandardContains("hotel")
            && (normalizedName.localizedStandardContains("restaurant")
                    || normalizedName.localizedStandardContains("dining")
                    || normalizedName.localizedStandardContains("bistro")
            )
        {
            return true
        }

        // Airport/station pattern
        if normalizedName.localizedStandardContains("airport")
            || normalizedName.localizedStandardContains("terminal")
            || normalizedName.localizedStandardContains("food hall")
        {
            return true
        }

        // Numbered restaurant pattern: "restaurant no. 5", "cafe #12"
        let numberedPattern = /(?:restaurant|cafe|diner|grill|kitchen)\s*(?:no\.?|#|number)\s*\d+/
        if normalizedName.contains(numberedPattern) {
            return true
        }

        // Too-short names (likely generic labels, not real restaurant names)
        if normalizedName.count <= 3 {
            return true
        }

        return false
    }

    private static let genericExactNames: Set<String> = [
        "restaurant",
        "restaurante",
        "ristorante",
        "restaurant & bar",
        "bar & restaurant",
        "bar restaurant",
        "dining room",
        "the dining room",
        "hotel restaurant",
        "cafe",
        "the cafe",
        "cafeteria",
        "canteen",
        "grill",
        "the grill",
        "grill room",
        "pizza",
        "pizzeria",
        "burger",
        "buffet",
        "the buffet",
        "food court",
        "staff restaurant",
        "employee restaurant",
        "bistro",
        "brasserie",
        "snack bar",
        "fast food",
        "diner",
        "the kitchen",
        "kitchen",
        "eatery",
        "food truck"
    ]
}

// MARK: - Known International Chain Database

extension CityRestaurantChainDetector {
    /// Keywords that strongly indicate chain restaurants when found within a name.
    /// These catch variations like "McDonald's Airport" or "Subway Central".
    private static let chainKeywords: Set<String> = [
        "mcdonald",
        "burger king",
        "subway",
        "starbucks",
        "kfc",
        "pizza hut",
        "domino",
        "taco bell",
        "wendy",
        "chick-fil-a",
        "popeyes",
        "dunkin",
        "tim hortons",
        "chipotle",
        "five guys",
        "nando",
        "wagamama",
        "pizza express",
        "pret a manger"
    ]

    /// Comprehensive set of known chain/franchise restaurant names worldwide.
    /// Covers fast food, fast casual, casual dining, and coffee chains.
    // swiftlint:disable:next closure_body_length
    private static let knownChains: Set<String> = {
        var chains: Set<String> = []

        // Global fast food
        let globalFastFood = [
            "mcdonald's", "mcdonalds", "burger king", "subway", "kfc",
            "kentucky fried chicken", "pizza hut", "domino's", "dominos",
            "domino's pizza", "taco bell", "wendy's", "wendys",
            "popeyes", "popeye's", "chick-fil-a", "five guys",
            "papa john's", "papa johns", "little caesars", "little caesar's",
            "sonic drive-in", "sonic", "jack in the box", "whataburger",
            "in-n-out", "in-n-out burger", "carl's jr", "carls jr",
            "hardee's", "hardees", "arby's", "arbys", "checkers",
            "rally's", "rallys", "del taco", "el pollo loco",
            "wingstop", "raising cane's", "raising canes",
            "church's chicken", "churchs chicken", "zaxby's", "zaxbys",
            "culver's", "culvers", "shake shack", "firehouse subs",
            "jersey mike's", "jersey mikes", "jimmy john's", "jimmy johns",
            "chipotle", "chipotle mexican grill", "qdoba", "moe's southwest grill"
        ]

        // Global casual dining
        let globalCasualDining = [
            "applebee's", "applebees", "chili's", "chilis",
            "olive garden", "red lobster", "outback steakhouse",
            "t.g.i. friday's", "tgi fridays", "tgi friday's",
            "buffalo wild wings", "denny's", "dennys",
            "ihop", "cracker barrel", "longhorn steakhouse",
            "texas roadhouse", "golden corral", "bob evans",
            "red robin", "the cheesecake factory", "cheesecake factory",
            "p.f. chang's", "pf changs", "benihana",
            "hooters", "bj's restaurant", "bjs restaurant",
            "cheddar's", "cheddars", "yard house",
            "ruth's chris", "ruths chris steak house",
            "morton's", "mortons", "capital grille",
            "seasons 52", "bahama breeze"
        ]

        // Coffee/bakery chains
        let coffeeChains = [
            "starbucks", "dunkin'", "dunkin", "dunkin' donuts",
            "tim hortons", "costa coffee", "costa", "peet's coffee", "peets coffee",
            "caribou coffee", "panera bread", "panera",
            "au bon pain", "corner bakery", "paris baguette",
            "tous les jours", "85°c", "85 degrees"
        ]

        // European chains
        let europeanChains = [
            "nando's", "nandos", "wagamama", "pizza express",
            "pret a manger", "pret", "leon", "itsu", "yo! sushi",
            "giraffe", "zizzi", "prezzo", "ask italian",
            "frankie & benny's", "harvester", "toby carvery",
            "beefeater", "brewers fayre", "hungry horse",
            "wetherspoons", "j d wetherspoon", "greggs",
            "paul", "flunch", "quick", "nordsee",
            "vapiano", "hans im gluck", "l'osteria", "dean & david",
            "block house", "maredo", "peter pane"
        ]

        // Asian chains
        let asianChains = [
            "yoshinoya", "sukiya", "matsuya", "coco ichibanya",
            "mos burger", "lotteria", "freshness burger",
            "ringer hut", "pepper lunch", "saizeriya",
            "gusto", "denny's japan", "jollibee",
            "chowking", "mang inasal", "greenwich",
            "din tai fung", "haidilao", "xiabu xiabu",
            "luckin coffee", "mixue", "coco tea",
            "gong cha", "tiger sugar", "the alley"
        ]

        // Middle East/Africa chains
        let menaChains = [
            "al baik", "kudu", "herfy", "al tazaj",
            "jasmis", "hardee's arabia", "shawarmer",
            "the butcher shop & grill", "ocean basket",
            "steers", "spur", "wimpy", "debonairs",
            "nando's south africa", "mugg & bean"
        ]

        // Latin America chains
        let latamChains = [
            "habib's", "habibs", "bob's burgers", "giraffas",
            "spoleto", "madero", "outback brazil",
            "pollo campero", "bembos"
        ]

        // Pizza chains
        let pizzaChains = [
            "papa murphy's", "papa murphys", "round table pizza",
            "marco's pizza", "marcos pizza", "hungry howie's",
            "cicis", "cici's pizza", "jet's pizza", "jets pizza",
            "mod pizza", "blaze pizza", "pieology",
            "california pizza kitchen", "cpk"
        ]

        for group in [
            globalFastFood, globalCasualDining, coffeeChains,
            europeanChains, asianChains, menaChains, latamChains, pizzaChains
        ] {
            for name in group {
                chains.insert(name)
            }
        }

        return chains
    }()
}
