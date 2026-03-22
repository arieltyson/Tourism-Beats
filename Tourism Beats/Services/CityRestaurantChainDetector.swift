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
        duplicateLocationCount: Int,
        detectedChainSignatures: Set<String> = []
    ) -> ChainConfidence {
        if hasBrandWikidata {
            return .high
        }

        let normalizedName = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if self.knownChains.contains(normalizedName) {
            return .high
        }

        if let brand {
            let normalizedBrand = brand
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if self.knownChains.contains(normalizedBrand) {
                return .high
            }
            if !normalizedBrand.isEmpty {
                return .medium
            }
        }

        if duplicateLocationCount >= 3 {
            return .high
        }

        if !detectedChainSignatures.isEmpty,
           self.matchesChainSignature(normalizedName, in: detectedChainSignatures)
        {
            return .high
        }

        if self.chainKeywords.contains(where: { normalizedName.localizedStandardContains($0) }) {
            return .medium
        }

        if duplicateLocationCount >= 2 {
            return .medium
        }

        if hasOperator {
            return .low
        }

        if self.isGenericPattern(normalizedName) {
            return .low
        }

        return .none
    }

    // MARK: - Wider-Radius Chain Detection

    struct RestaurantNameEntry: Sendable {
        let name: String
        let latitude: Double?
        let longitude: Double?
    }

    /// Analyzes a large set of restaurant names from a wider area scan.
    /// Returns the set of "core signatures" that appear at 3+ distinct locations,
    /// indicating chain/franchise restaurants.
    ///
    /// Uses a two-pass approach:
    /// 1. Group by exact normalized name (catches "Big Way Hot Pot" × 4)
    /// 2. Group by shared token prefix (catches "Big Way Hot Pot Richmond"
    ///    vs "Big Way Hot Pot Burnaby" by finding that "Big Way Hot Pot"
    ///    is a common prefix appearing at 3+ locations)
    static func detectChainSignatures(
        from entries: [RestaurantNameEntry]
    ) -> Set<String> {
        struct LocationEntry {
            let normalized: String
            let tokens: [String]
            let coordKey: String
        }

        let processed: [LocationEntry] = entries.compactMap { entry in
            let normalized = entry.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalized.count >= 3 else { return nil }

            let tokens = normalized
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            guard !tokens.isEmpty else { return nil }

            let coordKey = if let lat = entry.latitude, let lon = entry.longitude {
                "\(Int((lat * 1_000).rounded()))|\(Int((lon * 1_000).rounded()))"
            } else {
                "unknown-\(entry.name.hashValue)"
            }

            return LocationEntry(normalized: normalized, tokens: tokens, coordKey: coordKey)
        }

        var chainSignatures = Set<String>()

        // Pass 1: Exact name grouping
        var exactLocations: [String: Set<String>] = [:]
        for entry in processed {
            exactLocations[entry.normalized, default: []].insert(entry.coordKey)
        }
        for (name, locations) in exactLocations where locations.count >= 3 {
            chainSignatures.insert(name)
        }

        // Pass 2: Shared-prefix grouping
        // For each prefix length (2+ tokens), group by that prefix
        // and check if 3+ distinct coordinates share it.
        let maxPrefixLength = 6
        for prefixLen in stride(from: 2, through: maxPrefixLength, by: 1) {
            var prefixLocations: [String: Set<String>] = [:]
            for entry in processed where entry.tokens.count >= prefixLen {
                let prefix = entry.tokens.prefix(prefixLen).joined(separator: " ")
                prefixLocations[prefix, default: []].insert(entry.coordKey)
            }
            for (prefix, locations) in prefixLocations where locations.count >= 3 {
                chainSignatures.insert(prefix)
            }
        }

        return chainSignatures
    }

    /// Checks if a restaurant name matches any detected chain signature.
    /// Handles both exact matches and prefix matches (e.g., "Big Way Hot Pot Burnaby"
    /// matches signature "big way hot pot").
    static func matchesChainSignature(
        _ normalizedName: String,
        in signatures: Set<String>
    ) -> Bool {
        if signatures.contains(normalizedName) { return true }

        let tokens = normalizedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Check if any prefix of the name matches a chain signature
        for length in stride(from: min(tokens.count, 6), through: 2, by: -1) {
            let prefix = tokens.prefix(length).joined(separator: " ")
            if signatures.contains(prefix) { return true }
        }

        return false
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
        "pret a manger",
        "big way hot pot",
        "haidilao",
        "happy lamb",
        "little sheep",
        "din tai fung",
        "jollibee",
        "panda express",
        "bonchon",
        "gyu-kaku",
        "gong cha",
        "chatime"
    ]

    // Comprehensive set of known chain/franchise restaurant names worldwide.
    // Covers fast food, fast casual, casual dining, and coffee chains.
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
            "gong cha", "tiger sugar", "the alley",
            "big way hot pot", "happy lamb hot pot", "liuyishou",
            "little sheep", "morals village", "dolar shop",
            "boiling point", "kichi kichi", "mala tang",
            "hai di lao", "coco curu", "kung fu tea",
            "chatime", "sharetea", "presotea", "yi fang",
            "meet fresh", "panda express", "pei wei",
            "pick up stix", "sarku japan", "teriyaki madness",
            "bonchon", "bb.q chicken", "kyochon",
            "gen korean bbq", "kbbq", "gyu-kaku",
            "kintan buffet", "sushi zanmai", "genki sushi",
            "kura sushi", "sushiro", "hamazushi"
        ]

        // Middle East/Africa chains
        let menaChains = [
            "al baik", "kudu", "herfy", "al tazaj",
            "jasmis", "hardee's arabia", "shawarmer",
            "the butcher shop & grill", "ocean basket",
            "steers", "spur", "wimpy", "debonairs",
            "nando's south africa", "mugg & bean"
        ]

        // Canadian/Australian chains
        let canadianAustralianChains = [
            "boston pizza", "montana's", "swiss chalet",
            "harvey's", "mary brown's", "mary browns",
            "a&w", "the keg", "earls", "cactus club",
            "white spot", "milestone's", "milestones",
            "joey", "moxie's", "moxies", "original joe's",
            "red lobster canada", "kelsey's", "kelseys",
            "st-hubert", "scores", "baton rouge",
            "hungry jack's", "hungry jacks", "oporto",
            "grill'd", "nando's australia", "mad mex",
            "guzman y gomez", "zambrero"
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
            europeanChains, asianChains, menaChains,
            canadianAustralianChains, latamChains, pizzaChains
        ] {
            for name in group {
                chains.insert(name)
            }
        }

        return chains
    }()
}
