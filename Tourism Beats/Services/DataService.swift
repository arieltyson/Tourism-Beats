import CoreLocation
import Foundation

// MARK: - DataServiceError

enum DataServiceError: Error {
    case fileNotFound(String)
    case decodingError(Error)
}

// MARK: - CityJSON

// Raw JSON row
private struct CityJSON: Decodable {
    let name: String
    let countryCode: String
    let imageURL: URL
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let timeZoneIdentifier: String
}

// MARK: - DataService

@MainActor
final class DataService {
    // Shared decoders are cheaper than creating new ones repeatedly.
    private static let decoder = JSONDecoder()

    // Process-level caches (thread-safe enough for our usage; data is immutable)
    private static var cachedCountries: [CountryModel]?
    private static var cachedCities: [CityModel]?
    private static var cachedCountryLookup: [String: CountryModel]?

    // MARK: - Public API

    func loadCountries() throws -> [CountryModel] {
        if let c = Self.cachedCountries { return c }
        let countries: [CountryModel] = try self.loadJSON("countries.json")
        Self.cachedCountries = countries
        Self.cachedCountryLookup = Dictionary(
            uniqueKeysWithValues: countries.map { ($0.code, $0) }
        )
        return countries
    }

    func loadCities() throws -> [CityModel] {
        if let c = Self.cachedCities { return c }

        let lookup: [String: CountryModel]
        if let cached = Self.cachedCountryLookup {
            lookup = cached
        } else {
            let countries = try loadCountries()
            lookup = Dictionary(
                uniqueKeysWithValues: countries.map { ($0.code, $0) }
            )
            Self.cachedCountryLookup = lookup
        }

        let entries: [CityJSON] = try loadJSON("cities.json")
        let cities = entries.map { entry in
            let country =
                lookup[entry.countryCode]
                ?? CountryModel(
                    name: "Unknown",
                    code: entry.countryCode,
                    flag: "❓"
                )
            return CityModel(
                id: "\(entry.name)-\(entry.countryCode)",
                name: entry.name,
                country: country,
                imageURL: entry.imageURL,
                coordinate: .init(
                    latitude: entry.latitude,
                    longitude: entry.longitude
                ),
                timeZoneIdentifier: entry.timeZoneIdentifier
            )
        }
        Self.cachedCities = cities
        return cities
    }

    // MARK: - Helpers

    private func loadJSON<T: Decodable>(_ filename: String) throws -> T {
        guard
            let url = Bundle.main.url(forResource: filename, withExtension: nil)
        else { throw DataServiceError.fileNotFound(filename) }

        do {
            let data = try Data(contentsOf: url)
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw DataServiceError.decodingError(error)
        }
    }
}
