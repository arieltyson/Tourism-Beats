import Observation

/// Searches the city catalog for the map's search screen.
@MainActor
@Observable
final class CitySearchViewModel {
    /// How many cities to suggest before the user has typed anything.
    static let suggestionCount = 10

    /// Shorter queries are too ambiguous to correct for typos.
    static let minimumCorrectableQueryLength = 4

    /// Queries at least this long tolerate a second typo.
    static let twoTypoQueryLength = 8

    var query = ""

    @ObservationIgnored private let entries: [CitySearchEntry]

    init(cities: [CityModel]) {
        self.entries = cities.map(CitySearchEntry.init)
    }

    /// Cities matching the query, best first: names that start with it, then
    /// names with a word that does, then countries, then matches mid-word.
    /// When nothing matches, the closest spellings within a typo or two.
    /// With no query, a short list of suggestions.
    var results: [CityModel] {
        let query = CitySearchEntry.normalized(self.query)

        guard !query.isEmpty else {
            return self.entries.prefix(Self.suggestionCount).map(\.city)
        }

        let matches = self.entries.enumerated().compactMap { index, entry in
            entry.rank(for: query).map { (index: index, rank: $0, city: entry.city) }
        }

        guard matches.isEmpty else {
            return matches
                .sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }
                .map(\.city)
        }

        return self.corrections(for: query)
    }

    /// Whether a typed query found nothing, even allowing for typos.
    var hasNoResults: Bool {
        !CitySearchEntry.normalized(self.query).isEmpty && self.results.isEmpty
    }

    private func corrections(for query: String) -> [CityModel] {
        guard query.count >= Self.minimumCorrectableQueryLength else { return [] }

        let tolerance = query.count >= Self.twoTypoQueryLength ? 2 : 1

        return self.entries.enumerated()
            .compactMap { index, entry in
                entry.typoDistance(to: query, tolerance: tolerance)
                    .map { (index: index, distance: $0, city: entry.city) }
            }
            .sorted { ($0.distance, $0.index) < ($1.distance, $1.index) }
            .map(\.city)
    }
}
