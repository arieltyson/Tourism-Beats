import CoreLocation
import Testing
@testable import Tourism_Beats

@MainActor
struct TripCityLookupTests {
    @Test func tripsViewModelToleratesDuplicateCityCountryRows() {
        let haiti = CountryModel(name: "Haiti", code: "HT", flag: "🇭🇹")
        let portAuPrincePrimary = Self.makeCity(
            name: "Port-au-Prince",
            country: haiti,
            imageURLString: "https://example.com/port-au-prince-1.jpg"
        )
        let portAuPrinceDuplicate = Self.makeCity(
            name: "Port-au-Prince",
            country: haiti,
            imageURLString: "https://example.com/port-au-prince-2.jpg"
        )

        let viewModel = TripsViewModel(
            catalogCities: [portAuPrincePrimary, portAuPrinceDuplicate],
            countries: [haiti]
        )
        let trip = Trip(
            name: "Haiti Test Trip",
            city: "Port-au-Prince",
            country: "Haiti"
        )

        #expect(viewModel.cityModel(for: trip)?.imageURL == portAuPrincePrimary.imageURL)
        #expect(viewModel.countryFlag(for: trip) == "🇭🇹")
    }

    @Test func tripFormViewModelDeduplicatesCitySuggestions() {
        let haiti = CountryModel(name: "Haiti", code: "HT", flag: "🇭🇹")
        let portAuPrincePrimary = Self.makeCity(
            name: "Port-au-Prince",
            country: haiti,
            imageURLString: "https://example.com/port-au-prince-1.jpg"
        )
        let portAuPrinceDuplicate = Self.makeCity(
            name: "Port-au-Prince",
            country: haiti,
            imageURLString: "https://example.com/port-au-prince-2.jpg"
        )

        let viewModel = TripFormViewModel(
            countryName: "Haiti",
            countries: [haiti],
            cities: [portAuPrincePrimary, portAuPrinceDuplicate]
        )

        let suggestions = viewModel.matchingCities(for: "Port")

        #expect(suggestions.count == 1)
        #expect(suggestions.first?.name == "Port-au-Prince")
        #expect(suggestions.first?.country.name == "Haiti")
    }

    private static func makeCity(
        name: String,
        country: CountryModel,
        imageURLString: String
    ) -> CityModel {
        let imageURL = URL(string: imageURLString) ?? URL.documentsDirectory

        return CityModel(
            id: "\(name)-\(country.code)",
            name: name,
            country: country,
            imageURL: imageURL,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "America/Port-au-Prince"
        )
    }
}
