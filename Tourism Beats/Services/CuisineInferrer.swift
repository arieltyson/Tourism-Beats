import Foundation

// MARK: - CuisineInferrer

/// Infers cuisine type from a restaurant name using keyword matching.
/// Used as a fallback when OSM cuisine data is unavailable.
enum CuisineInferrer {
    /// Attempts to infer a cuisine label from the restaurant name.
    /// Returns `nil` if no confident match is found — avoids guessing.
    static func infer(from name: String) -> String? {
        let normalized = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        // Check exact word boundaries first (higher confidence)
        for rule in self.rules {
            for keyword in rule.keywords where self.containsWord(keyword, in: normalized) {
                return rule.cuisine
            }
        }

        return nil
    }

    /// Checks if a keyword appears as a whole word (not a substring of another word).
    /// "thai" matches "thai basil" but not "thailand travel agency".
    private static func containsWord(_ word: String, in text: String) -> Bool {
        // For single-character words or very short words, require exact positioning
        guard word.count >= 3 else {
            return text == word
                || text.hasPrefix("\(word) ")
                || text.hasSuffix(" \(word)")
                || text.localizedStandardContains(" \(word) ")
        }

        // For longer words, localizedStandardContains is reliable enough
        return text.localizedStandardContains(word)
    }
}

// MARK: - Inference Rules

extension CuisineInferrer {
    private struct Rule: Sendable {
        let cuisine: String
        let keywords: [String]
    }

    /// Rules ordered by specificity — more specific matches first.
    /// Each rule maps a set of name keywords to a cuisine label.
    private static let rules: [Rule] = [
        // Japanese
        Rule(cuisine: "Japanese", keywords: [
            "sushi", "ramen", "izakaya", "yakitori", "tempura",
            "udon", "soba", "tonkatsu", "gyukatsu", "okonomiyaki",
            "teppanyaki", "kaiseki", "omakase", "donburi", "katsu",
            "matcha", "mochi", "onigiri", "gyoza", "robata",
            "yakiniku", "sukiyaki", "shabu"
        ]),

        // Italian
        Rule(cuisine: "Italian", keywords: [
            "trattoria", "osteria", "ristorante", "pizzeria",
            "pasta", "gelato", "enoteca", "focacceria",
            "panetteria", "paninoteca", "salumeria"
        ]),

        // Mexican / Latin
        Rule(cuisine: "Mexican", keywords: [
            "taqueria", "taco", "burrito", "cantina", "mezcal",
            "enchilada", "tamale", "elote", "pozole", "mole",
            "tortilleria", "cevicheria"
        ]),

        // Thai
        Rule(cuisine: "Thai", keywords: [
            "thai", "pad thai", "tom yum", "som tum",
            "satay", "massaman"
        ]),

        // Chinese
        Rule(cuisine: "Chinese", keywords: [
            "dim sum", "dumpling", "wok", "szechuan", "sichuan",
            "cantonese", "hunan", "peking", "bao", "congee",
            "hotpot", "hot pot", "noodle house", "chow mein",
            "kung pao", "mapo"
        ]),

        // Korean
        Rule(cuisine: "Korean", keywords: [
            "korean", "bibimbap", "bulgogi", "kimchi",
            "galbi", "kbbq", "banchan", "tteokbokki",
            "japchae", "samgyeopsal", "chimaek"
        ]),

        // Vietnamese
        Rule(cuisine: "Vietnamese", keywords: [
            "pho", "banh mi", "vietnamese", "bun bo",
            "com tam", "goi cuon"
        ]),

        // Indian
        Rule(cuisine: "Indian", keywords: [
            "tandoori", "masala", "biryani", "tikka",
            "naan", "curry house", "dosa", "chaat",
            "thali", "paneer", "vindaloo", "korma",
            "dal", "samosa"
        ]),

        // French
        Rule(cuisine: "French", keywords: [
            "bistro", "brasserie", "creperie", "patisserie",
            "boulangerie", "bouchon", "brasserie",
            "beurre", "croissant", "macaron"
        ]),

        // Mediterranean / Greek
        Rule(cuisine: "Mediterranean", keywords: [
            "mediterranean", "falafel", "hummus", "shawarma",
            "kebab", "gyro", "souvlaki", "taverna",
            "meze", "mezze", "pita"
        ]),

        // Spanish
        Rule(cuisine: "Spanish", keywords: [
            "tapas", "paella", "churros", "bodega",
            "sangria", "pintxos", "taberna"
        ]),

        // Turkish / Middle Eastern
        Rule(cuisine: "Turkish", keywords: [
            "kebap", "kofte", "lahmacun", "pide",
            "baklava", "doner"
        ]),

        // Seafood
        Rule(cuisine: "Seafood", keywords: [
            "seafood", "oyster", "lobster", "crab shack",
            "fish market", "clam", "fish bar"
        ]),

        // Steakhouse
        Rule(cuisine: "Steakhouse", keywords: [
            "steakhouse", "steak house", "chophouse",
            "chop house", "prime rib", "churrascaria",
            "rodizio"
        ]),

        // BBQ
        Rule(cuisine: "BBQ", keywords: [
            "bbq", "barbecue", "barbeque", "smokehouse",
            "smoke house", "pit"
        ]),

        // Bakery / Cafe
        Rule(cuisine: "Bakery", keywords: [
            "bakery", "bakehouse", "bake shop",
            "bread", "sourdough"
        ]),

        // Brazilian
        Rule(cuisine: "Brazilian", keywords: [
            "acai", "brigadeiro", "feijoada",
            "picanha", "caipirinha"
        ]),

        // Ethiopian
        Rule(cuisine: "Ethiopian", keywords: [
            "ethiopian", "injera", "berbere", "kitfo"
        ]),

        // Peruvian
        Rule(cuisine: "Peruvian", keywords: [
            "peruvian", "ceviche", "lomo saltado",
            "anticucho"
        ]),

        // Lebanese
        Rule(cuisine: "Lebanese", keywords: [
            "lebanese", "fattoush", "tabbouleh", "kibbeh",
            "manoushe"
        ]),

        // Pizza (distinct from Italian — standalone pizza joints)
        Rule(cuisine: "Pizza", keywords: [
            "pizza"
        ]),

        // Burger
        Rule(cuisine: "Burgers", keywords: [
            "burger", "smash burger"
        ]),

        // Cafe
        Rule(cuisine: "Cafe", keywords: [
            "cafe", "coffee", "espresso"
        ])
    ]
}
