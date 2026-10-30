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
        #expect(viewModel.hasNoResults)
    }

    @Test func citiesStartingWithTheQueryComeFirst() {
        let viewModel = CitySearchViewModel(cities: [
            Self.city("Lima", country: "Peru"),
            Self.city("Panama City", country: "Panama"),
            Self.city("Madrid", country: "Spain"),
            Self.city("Manila", country: "Philippines")
        ])

        viewModel.query = "ma"

        #expect(viewModel.results.map(\.id) == ["madrid", "manila", "lima", "panama-city"])
    }

    @Test func anyWordInTheNameCanStartTheMatch() {
        let viewModel = CitySearchViewModel(cities: [
            Self.city("Fernandina", country: "Chile"),
            Self.city("San Fernando", country: "Trinidad and Tobago")
        ])

        viewModel.query = "fern"

        #expect(viewModel.results.map(\.id) == ["fernandina", "san-fernando"])
    }

    @Test func punctuationInNamesIsIgnored() {
        let viewModel = CitySearchViewModel(cities: [Self.city("Cluj-Napoca", country: "Romania")])

        viewModel.query = "cluj napoca"

        #expect(viewModel.results.map(\.id) == ["cluj-napoca"])
    }

    @Test(arguments: [
        ("Maldova", "chisinau"),
        ("Prais", "paris"),
        ("Barcelonna", "barcelona")
    ])
    func misspellingsFindTheClosestCity(query: String, expectedID: String) {
        let viewModel = CitySearchViewModel(cities: [
            Self.city("Chisinau", country: "Moldova"),
            Self.city("Paris", country: "France"),
            Self.city("Barcelona", country: "Spain")
        ])

        viewModel.query = query

        #expect(viewModel.results.map(\.id) == [expectedID])
        #expect(!viewModel.hasNoResults)
    }

    @Test func shortQueriesAreNotCorrected() {
        let viewModel = CitySearchViewModel(cities: [Self.city("Rome", country: "Italy")])

        viewModel.query = "rme"

        #expect(viewModel.results.isEmpty)
        #expect(viewModel.hasNoResults)
    }

    @Test func emptyQueryIsNeverReportedAsNoResults() {
        let viewModel = CitySearchViewModel(cities: [])

        viewModel.query = " "

        #expect(!viewModel.hasNoResults)
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
