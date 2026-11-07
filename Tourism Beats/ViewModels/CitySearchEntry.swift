import Foundation

// MARK: - CitySearchEntry

/// A city prepared for search: its city, state, and country names, and any
/// other names it goes by, folded to plain lowercase words, so "sao paulo"
/// finds São Paulo, "cluj napoca" finds Cluj-Napoca, "kashmir" finds Srinagar,
/// and "utah" finds Lehi.
struct CitySearchEntry {
    /// How well a city matches, best first.
    enum Rank: Int, Comparable {
        case namePrefix
        case nameWordPrefix
        case regionWordPrefix
        case nameContains
        case regionContains

        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let city: CityModel
    /// The city's name followed by its aliases, which match just as well.
    private let names: [String]
    /// The state or province, if any, and the country.
    private let regions: [String]
    /// The name from each word onward: "san fernando" gives "san fernando"
    /// and "fernando", so typing the start of any word matches.
    private let nameWordStarts: [String]
    private let regionWordStarts: [String]

    init(city: CityModel) {
        self.city = city
        self.names = ([city.name] + city.searchAliases).map(Self.normalized)
        self.regions = [city.administrativeArea, city.country.name].compactMap(\.self).map(Self.normalized)
        self.nameWordStarts = self.names.flatMap(Self.wordStarts(of:))
        self.regionWordStarts = self.regions.flatMap(Self.wordStarts(of:))
    }

    /// Lowercases, drops accents, and turns punctuation into single spaces.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
    }

    /// How this city matches a normalized query, or `nil` if it doesn't.
    func rank(for query: String) -> Rank? {
        if self.names.contains(where: { $0.hasPrefix(query) }) {
            .namePrefix
        } else if self.nameWordStarts.contains(where: { $0.hasPrefix(query) }) {
            .nameWordPrefix
        } else if self.regionWordStarts.contains(where: { $0.hasPrefix(query) }) {
            .regionWordPrefix
        } else if self.names.contains(where: { $0.contains(query) }) {
            .nameContains
        } else if self.regions.contains(where: { $0.contains(query) }) {
            .regionContains
        } else {
            nil
        }
    }

    /// The fewest typos separating a normalized query from the start of any
    /// word in the city, state, or country name, if within `tolerance`.
    func typoDistance(to query: String, tolerance: Int) -> Int? {
        let closest = (self.nameWordStarts + self.regionWordStarts)
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
