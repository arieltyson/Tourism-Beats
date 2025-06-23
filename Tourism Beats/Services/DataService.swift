import CoreLocation
import Foundation

/// Errors this service can throw when loading your bundled JSON.
enum DataServiceError: Error {
    case fileNotFound(String)
    case decodingError(Error)
}

/// Matches the shape of each record in `cities.json`.
private struct CityJSON: Decodable {
    let name: String
    let countryCode: String
    let imageName: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let timeZoneIdentifier: String
}

/// Loads & links `CountryModel` + `CityModel` from your bundled JSON.
final class DataService {
    /// Load all countries from `countries.json`.
    func loadCountries() throws -> [CountryModel] {
        try loadJSON("countries.json")
    }

    /// Load all cities from `cities.json`, then look up each city’s `CountryModel` by code.
    func loadCities() throws -> [CityModel] {
        // 1) decode countries
        let countries = try loadCountries()
        let lookup = Dictionary(
            uniqueKeysWithValues: countries.map { ($0.code, $0) }
        )

        // 2) decode raw city entries
        let cityEntries: [CityJSON] = try loadJSON("cities.json")

        // 3) map into your strongly-typed CityModel
        return cityEntries.map { entry in
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
                imageName: entry.imageName,
                coordinate: CLLocationCoordinate2D(
                    latitude: entry.latitude,
                    longitude: entry.longitude
                ),
                timeZoneIdentifier: entry.timeZoneIdentifier
            )
        }
    }

    /// Generic helper: load & decode any `Decodable` T from a bundled file.
    private func loadJSON<T: Decodable>(_ filename: String) throws -> T {
        guard
            let url = Bundle.main.url(forResource: filename, withExtension: nil)
        else { throw DataServiceError.fileNotFound(filename) }

        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DataServiceError.decodingError(error)
        }
    }
}
