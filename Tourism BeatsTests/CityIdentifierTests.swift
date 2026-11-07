import Testing
@testable import Tourism_Beats

// MARK: - CityIdentifierTests

@MainActor
struct CityIdentifierTests {
    @Test func aCityWithItsOwnNameKeepsTheShortForm() {
        let identifier = CityModel.identifier(
            name: "Lehi",
            administrativeArea: "Utah",
            countryCode: "US",
            sharesName: false
        )
        #expect(identifier == "Lehi-US")
    }

    @Test func citiesSharingANameAreToldApartByState() {
        let maine = CityModel.identifier(name: "Portland", administrativeArea: "Maine", countryCode: "US", sharesName: true)
        let oregon = CityModel.identifier(name: "Portland", administrativeArea: "Oregon", countryCode: "US", sharesName: true)

        #expect(maine == "Portland-Maine-US")
        #expect(oregon == "Portland-Oregon-US")
    }

    /// Activities, restaurants, and facts are cached under the identifier, so
    /// no two catalog cities may share one.
    @Test func everyCatalogCityHasItsOwnIdentifier() throws {
        let cities = try DataService().loadCities()
        let identifiers = cities.map(\.id)
        let repeated = Dictionary(grouping: identifiers, by: \.self).filter { $0.value.count > 1 }.keys

        #expect(repeated.isEmpty, "\(repeated.sorted())")
    }
}
