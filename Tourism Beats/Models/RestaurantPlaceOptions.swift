import Foundation

// MARK: - RestaurantPlaceOptions

/// The cities and countries the restaurant form offers, and how they are searched.
struct RestaurantPlaceOptions: Sendable {
    /// Places already in the journal, most recent first.
    let journalPlaces: [RestaurantPlace]
    /// Every city in the app's catalog, alphabetized.
    let catalogPlaces: [RestaurantPlace]
    /// Every country, alphabetized.
    let countries: [CountryModel]

    static let empty = RestaurantPlaceOptions(journalPlaces: [], catalogPlaces: [], countries: [])

    /// Journal and catalog places matching the query, best matches first.
    ///
    /// A city whose name starts with the query ranks above one that only
    /// contains it, which ranks above one matched by country or another name.
    /// Ties keep journal places ahead of catalog places.
    func places(matching query: String) -> [RestaurantPlace] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        var seenIdentifiers = Set<String>()
        let candidates = (self.journalPlaces + self.catalogPlaces).filter {
            seenIdentifiers.insert($0.id).inserted
        }

        return candidates
            .enumerated()
            .compactMap { offset, place in
                Self.rank(of: place, for: trimmedQuery).map { (rank: $0, offset: offset, place: place) }
            }
            .sorted { ($0.rank, $0.offset) < ($1.rank, $1.offset) }
            .map(\.place)
    }

    /// Countries matching the query by name or code, names starting with it first.
    func countries(matching query: String) -> [CountryModel] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return self.countries }

        let matches = self.countries.filter {
            $0.name.localizedStandardContains(trimmedQuery)
                || $0.code.caseInsensitiveCompare(trimmedQuery) == .orderedSame
        }
        let prefixMatches = matches.filter { Self.hasPrefix($0.name, trimmedQuery) }
        return prefixMatches + matches.filter { !Self.hasPrefix($0.name, trimmedQuery) }
    }

    // MARK: - Ranking

    private static func rank(of place: RestaurantPlace, for query: String) -> Int? {
        if self.hasPrefix(place.city, query) {
            return 0
        }
        if place.city.localizedStandardContains(query) {
            return 1
        }
        if ([place.country] + place.searchAliases).contains(where: { $0.localizedStandardContains(query) }) {
            return 2
        }
        return nil
    }

    private static func hasPrefix(_ value: String, _ query: String) -> Bool {
        value.range(of: query, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil
    }
}
