import Testing
@testable import Tourism_Beats

// MARK: - RestaurantPlaceOptionsTests

struct RestaurantPlaceOptionsTests {
    private let options = RestaurantPlaceOptions(
        journalPlaces: [
            RestaurantPlace(city: "Las Vegas", country: "United States", flag: "🇺🇸"),
        ],
        catalogPlaces: [
            RestaurantPlace(city: "City of Victoria", country: "Hong Kong", flag: "🇭🇰"),
            RestaurantPlace(city: "Fira", country: "Greece", flag: "🇬🇷", searchAliases: ["Santorini"]),
            RestaurantPlace(city: "Las Vegas", country: "United States", flag: "🇺🇸"),
            RestaurantPlace(city: "Victoria", country: "Canada", flag: "🇨🇦"),
            RestaurantPlace(city: "Victoria", country: "Seychelles", flag: "🇸🇨"),
        ],
        countries: [
            CountryModel(name: "Canada", code: "CA", flag: "🇨🇦"),
            CountryModel(name: "Central African Republic", code: "CF", flag: "🇨🇫"),
            CountryModel(name: "Greece", code: "GR", flag: "🇬🇷"),
            CountryModel(name: "South Africa", code: "ZA", flag: "🇿🇦"),
        ]
    )

    @Test func emptyQueryReturnsNoSearchResults() {
        #expect(self.options.places(matching: "  ").isEmpty)
    }

    @Test func citiesStartingWithTheQueryRankFirst() {
        let cities = self.options.places(matching: "victori").map(\.city)

        #expect(cities == ["Victoria", "Victoria", "City of Victoria"])
    }

    @Test func sameNamedCitiesStayApartByCountry() {
        let countries = self.options.places(matching: "Victoria")
            .filter { $0.city == "Victoria" }
            .map(\.country)

        #expect(countries == ["Canada", "Seychelles"])
    }

    @Test func journalPlacesAreListedOnceAheadOfTheCatalog() {
        let results = self.options.places(matching: "las")

        #expect(results.count == 1)
        #expect(results.first?.country == "United States")
    }

    @Test func citiesAreFoundByCountryOrOtherName() {
        #expect(self.options.places(matching: "Santorini").map(\.city) == ["Fira"])
        #expect(self.options.places(matching: "Greece").map(\.city) == ["Fira"])
    }

    @Test func searchIgnoresCaseAndAccents() {
        #expect(self.options.places(matching: "FÍRA").map(\.city) == ["Fira"])
    }

    @Test func countriesStartingWithTheQueryRankFirst() {
        let names = self.options.countries(matching: "Afric").map(\.name)

        #expect(names == ["Central African Republic", "South Africa"])
        #expect(self.options.countries(matching: "ca").map(\.name).first == "Canada")
    }

    @Test func emptyCountryQueryListsEveryCountry() {
        #expect(self.options.countries(matching: "").count == 4)
    }
}
