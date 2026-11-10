import Foundation

/// The cities and countries the Food Journal matches restaurants against
/// and offers when adding one, sorted and keyed for lookup.
struct FoodCatalog: Sendable {
    let citiesByNormalizedName: [String: [CityModel]]
    /// Every catalog city as a place to choose, alphabetically.
    let places: [RestaurantPlace]
    /// Every country, alphabetically.
    let countries: [CountryModel]
    let flagsByNormalizedCountryName: [String: String]

    /// The bundled catalog, built once: sorting and folding hundreds of
    /// names is too slow to repeat each time the Food tab is created.
    @MainActor static let bundled: FoodCatalog = {
        let dataService = DataService()
        return FoodCatalog(
            cities: (try? dataService.loadCities()) ?? [],
            countries: (try? dataService.loadCountries()) ?? []
        )
    }()

    init(cities: [CityModel], countries: [CountryModel]) {
        citiesByNormalizedName = Dictionary(
            grouping: cities,
            by: { FoodJournalCityGroup.normalizedLookupValue($0.name) }
        )
        places = cities
            .map {
                RestaurantPlace(
                    city: $0.name,
                    country: $0.country.name,
                    flag: $0.country.flag,
                    searchAliases: $0.searchAliases
                )
            }
            .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
        self.countries = countries
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        flagsByNormalizedCountryName = Dictionary(
            countries.map { (FoodJournalCityGroup.normalizedLookupValue($0.name), $0.flag) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// The catalog city with this name in the country with this code.
    func city(named name: String, countryCode: String) -> CityModel? {
        self.citiesByNormalizedName[FoodJournalCityGroup.normalizedLookupValue(name)]?
            .first { $0.country.code == countryCode }
    }
}
