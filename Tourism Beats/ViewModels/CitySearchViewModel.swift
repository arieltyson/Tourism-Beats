import Observation

/// Filters the city catalog for the map's search screen.
@MainActor
@Observable
final class CitySearchViewModel {
    /// How many cities to suggest before the user has typed anything.
    static let suggestionCount = 10

    var query = ""

    @ObservationIgnored private let cities: [CityModel]

    init(cities: [CityModel]) {
        self.cities = cities
    }

    /// Cities whose name matches the query, followed by cities whose
    /// country matches, or a short list of suggestions when the query is empty.
    var results: [CityModel] {
        let query = self.query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return Array(self.cities.prefix(Self.suggestionCount))
        }

        var nameMatches: [CityModel] = []
        var countryMatches: [CityModel] = []

        for city in self.cities {
            if city.name.localizedStandardContains(query) {
                nameMatches.append(city)
            } else if city.country.name.localizedStandardContains(query) {
                countryMatches.append(city)
            }
        }

        return nameMatches + countryMatches
    }
}
