import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

struct CityLocationNameTests {
    @Test func aStateTakesTheCountrysPlaceInTheShortName() {
        let city = Self.city("Lehi", country: "United States of America", administrativeArea: "Utah")

        #expect(city.displayName == "Lehi, Utah")
        #expect(city.regionName == "Utah")
    }

    @Test func theFullLocationKeepsBothStateAndCountry() {
        let city = Self.city("Lehi", country: "United States of America", administrativeArea: "Utah")

        #expect(city.locationName == "Utah, United States of America")
    }

    @Test func citiesWithoutAStateUseTheirCountry() {
        let city = Self.city("Nancy", country: "France")

        #expect(city.displayName == "Nancy, France")
        #expect(city.regionName == "France")
        #expect(city.locationName == "France")
    }

    @Test func theStateIsSearchableAlongsideAliases() {
        let city = Self.city(
            "Avalon",
            country: "United States of America",
            administrativeArea: "California",
            aliases: ["Catalina"]
        )

        #expect(city.alternateSearchNames == ["Catalina", "California"])
    }

    private static func city(
        _ name: String,
        country: String,
        administrativeArea: String? = nil,
        aliases: [String] = []
    ) -> CityModel {
        CityModel(
            id: name,
            name: name,
            country: CountryModel(name: country, code: "TT", flag: ""),
            administrativeArea: administrativeArea,
            imageURL: URL.documentsDirectory,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC",
            searchAliases: aliases
        )
    }
}
