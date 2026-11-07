import Observation

/// Searches the city catalog for the map's search screen.
@MainActor
@Observable
final class CitySearchViewModel {
    /// How many cities to suggest before the user has typed anything, when
    /// none of the chosen suggestions are in the catalog.
    static let suggestionCount = 10

    /// The cities suggested before anything is typed, in order: the world's
    /// great destinations, and a few close to home.
    static let suggestedCityIDs = [
        "London-GB",
        "Paris-FR",
        "New York-US",
        "Tokyo-JP",
        "Berlin-DE",
        "Barcelona-ES",
        "Rome-IT",
        "Beijing-CN",
        "Vancouver-CA",
        "San Fernando-TT",
        "New Delhi-IN",
    ]

    /// Shorter queries are too ambiguous to correct for typos.
    static let minimumCorrectableQueryLength = 4

    /// Queries at least this long tolerate a second typo.
    static let twoTypoQueryLength = 8

    var query = ""

    @ObservationIgnored private let entries: [CitySearchEntry]
    @ObservationIgnored private let suggestions: [CityModel]

    init(cities: [CityModel], suggestedCityIDs: [String] = CitySearchViewModel.suggestedCityIDs) {
        self.entries = cities.map(CitySearchEntry.init)

        let citiesByID = Dictionary(cities.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let suggested = suggestedCityIDs.compactMap { citiesByID[$0] }
        self.suggestions = suggested.isEmpty ? Array(cities.prefix(Self.suggestionCount)) : suggested
    }

    /// Cities matching the query, best first: names that start with it, then
    /// names with a word that does, then states and countries, then matches mid-word.
    /// When nothing matches, the closest spellings within a typo or two.
    /// With no query, the suggested cities.
    var results: [CityModel] {
        let query = CitySearchEntry.normalized(self.query)

        guard !query.isEmpty else {
            return self.suggestions
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
