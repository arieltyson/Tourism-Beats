import Foundation

// MARK: - TripFormViewModel

/// Provides country and city selection data for the trip composer.
@MainActor
@Observable
final class TripFormViewModel {
    var selectedCountryCode: String
    var isCountryPickerPresented: Bool = false

    private let countriesByCode: [String: CountryModel]
    private let countryCodesByNormalizedName: [String: String]
    private let allCities: [CityModel]

    init(
        countryName: String = "",
        dataService: DataService = DataService()
    ) {
        let countries = (try? dataService.loadCountries()) ?? []
        self.countriesByCode = Dictionary(
            uniqueKeysWithValues: countries.map { ($0.code, $0) }
        )
        self.countryCodesByNormalizedName = Dictionary(
            uniqueKeysWithValues: countries.map {
                (Self.normalizedLookupValue($0.name), $0.code)
            }
        )
        self.allCities = (try? dataService.loadCities()) ?? []
        self.selectedCountryCode =
            self.countryCodesByNormalizedName[Self.normalizedLookupValue(countryName)] ?? ""
    }

    var selectedCountry: CountryModel? {
        self.countriesByCode[self.selectedCountryCode]
    }

    var selectedCountryName: String {
        self.selectedCountry?.name ?? ""
    }

    var selectedCountryDisplayLabel: String {
        guard let selectedCountry else { return "Choose a country" }
        return "\(selectedCountry.flag) \(selectedCountry.name)"
    }

    func synchronizeCountrySelection(with countryName: String) {
        let normalizedCountryName = Self.normalizedLookupValue(countryName)
        self.selectedCountryCode =
            self.countryCodesByNormalizedName[normalizedCountryName] ?? ""
    }

    func matchingCities(for query: String) -> [CityModel] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let countryScopedCities: [CityModel] = if self.selectedCountryCode.isEmpty {
            self.allCities
        } else {
            self.allCities.filter { $0.country.code == self.selectedCountryCode }
        }

        let filteredCities: [CityModel] = if trimmedQuery.isEmpty {
            countryScopedCities
        } else {
            countryScopedCities.filter { city in
                city.name.localizedStandardContains(trimmedQuery)
                    || city.country.name.localizedStandardContains(trimmedQuery)
            }
        }

        return filteredCities.sorted { lhs, rhs in
            if lhs.name != rhs.name {
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
            return lhs.country.name.localizedCompare(rhs.country.name) == .orderedAscending
        }
    }

    func applySelection(for city: CityModel) -> TripLocationSelection {
        self.selectedCountryCode = city.country.code
        return TripLocationSelection(
            cityName: city.name,
            countryName: city.country.name
        )
    }

    private static func normalizedLookupValue(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - TripLocationSelection

struct TripLocationSelection: Sendable {
    let cityName: String
    let countryName: String
}
