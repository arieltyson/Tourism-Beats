import Foundation

/// Finds the catalog city and country flag for a trip's place names,
/// matching regardless of case and accents.
struct TripCatalog: Sendable {
    private let citiesByLookupKey: [String: CityModel]
    private let flagsByNormalizedCountry: [String: String]

    /// The bundled catalog, built once: folding hundreds of names is too
    /// slow to repeat each time a trips screen is created.
    @MainActor static let bundled: TripCatalog = {
        let dataService = DataService()
        return TripCatalog(
            cities: (try? dataService.loadCities()) ?? [],
            countries: (try? dataService.loadCountries()) ?? []
        )
    }()

    init(cities: [CityModel], countries: [CountryModel]) {
        // The catalog can contain duplicate rows for one city; the first wins.
        citiesByLookupKey = cities.reduce(into: [:]) { lookup, city in
            let key = Self.lookupKey(cityName: city.name, countryName: city.country.name)
            if lookup[key] == nil { lookup[key] = city }
        }
        flagsByNormalizedCountry = countries.reduce(into: [:]) { lookup, country in
            lookup[Self.normalized(country.name)] = country.flag
        }
    }

    func city(named cityName: String, in countryName: String) -> CityModel? {
        citiesByLookupKey[Self.lookupKey(cityName: cityName, countryName: countryName)]
    }

    func flag(forCountryNamed countryName: String) -> String? {
        flagsByNormalizedCountry[Self.normalized(countryName)]
    }

    private static func lookupKey(cityName: String, countryName: String) -> String {
        "\(normalized(cityName))|\(normalized(countryName))"
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
