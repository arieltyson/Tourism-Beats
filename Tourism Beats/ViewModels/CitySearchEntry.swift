import Foundation

// MARK: - CitySearchEntry

/// A city prepared for search: its city and country names folded to plain
/// lowercase words, so "sao paulo" finds São Paulo and "cluj napoca" finds
/// Cluj-Napoca.
struct CitySearchEntry {
    /// How well a city matches, best first.
    enum Rank: Int, Comparable {
        case namePrefix
        case nameWordPrefix
        case countryWordPrefix
        case nameContains
        case countryContains

        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let city: CityModel
    private let name: String
    private let country: String
    /// The name from each word onward: "san fernando" gives "san fernando"
    /// and "fernando", so typing the start of any word matches.
    private let nameWordStarts: [String]
    private let countryWordStarts: [String]

    init(city: CityModel) {
        self.city = city
        self.name = Self.normalized(city.name)
        self.country = Self.normalized(city.country.name)
        self.nameWordStarts = Self.wordStarts(of: self.name)
        self.countryWordStarts = Self.wordStarts(of: self.country)
    }

    /// Lowercases, drops accents, and turns punctuation into single spaces.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
    }

    /// How this city matches a normalized query, or `nil` if it doesn't.
    func rank(for query: String) -> Rank? {
        if self.name.hasPrefix(query) {
            .namePrefix
        } else if self.nameWordStarts.contains(where: { $0.hasPrefix(query) }) {
            .nameWordPrefix
        } else if self.countryWordStarts.contains(where: { $0.hasPrefix(query) }) {
            .countryWordPrefix
        } else if self.name.contains(query) {
            .nameContains
        } else if self.country.contains(query) {
            .countryContains
        } else {
            nil
        }
    }

    /// The fewest typos separating a normalized query from the start of any
    /// word in the city or country name, if within `tolerance`.
    func typoDistance(to query: String, tolerance: Int) -> Int? {
        let closest = (self.nameWordStarts + self.countryWordStarts)
            .map { String($0.prefix(query.count)).editDistance(to: query) }
            .min()

        return closest.flatMap { $0 <= tolerance ? $0 : nil }
    }

    private static func wordStarts(of text: String) -> [String] {
        text.indices
            .filter { $0 == text.startIndex || text[text.index(before: $0)] == " " }
            .map { String(text[$0...]) }
    }
}
