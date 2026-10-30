import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - CitySearchViewModelTests

@MainActor
struct CitySearchViewModelTests {
    @Test func emptyQuerySuggestsTheFirstCities() {
        let cities = (0 ..< CitySearchViewModel.suggestionCount + 5).map {
            Self.city("City \($0)", country: "Country \($0)")
        }
        let viewModel = CitySearchViewModel(cities: cities)

        #expect(viewModel.results.map(\.id) == cities.prefix(CitySearchViewModel.suggestionCount).map(\.id))
    }

    @Test func whitespaceOnlyQueryIsTreatedAsEmpty() {
        let cities = [Self.city("Paris", country: "France")]
        let viewModel = CitySearchViewModel(cities: cities)

        viewModel.query = "   "

        #expect(viewModel.results.map(\.id) == ["paris"])
    }

    @Test func cityNameMatchesComeBeforeCountryMatches() {
        let viewModel = CitySearchViewModel(cities: [
            Self.city("Lyon", country: "France"),
            Self.city("Franceville", country: "Gabon"),
            Self.city("Paris", country: "France")
        ])

        viewModel.query = "france"

        #expect(viewModel.results.map(\.id) == ["franceville", "lyon", "paris"])
    }

    @Test func matchingIgnoresCaseAndDiacritics() {
        let viewModel = CitySearchViewModel(cities: [
            Self.city("São Paulo", country: "Brazil"),
            Self.city("Lima", country: "Peru")
        ])

        viewModel.query = "SAO"

        #expect(viewModel.results.map(\.id) == ["são-paulo"])
    }

    @Test func unmatchedQueryReturnsNoResults() {
        let viewModel = CitySearchViewModel(cities: [Self.city("Tokyo", country: "Japan")])

        viewModel.query = "Atlantis"

        #expect(viewModel.results.isEmpty)
    }

    private static func city(_ name: String, country: String) -> CityModel {
        CityModel(
            id: name.lowercased().replacing(" ", with: "-"),
            name: name,
            country: CountryModel(name: country, code: "XX", flag: ""),
            imageURL: URL.documentsDirectory,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC"
        )
    }
}
