import Foundation
import Testing

struct CityCatalogCoverageTests {
    @Test func requestedCitiesArePresentWithWalkabilityCoverage() throws {
        let cityKeys = try Self.loadCityKeys()
        let walkabilityKeys = try Self.loadWalkabilityKeys()
        let requestedKeys: Set<String> = [
            Self.lookupKey(city: "Canberra", countryCode: "AU"),
            Self.lookupKey(city: "Kathmandu", countryCode: "NP"),
            Self.lookupKey(city: "Thimphu", countryCode: "BT"),
            Self.lookupKey(city: "Gold Coast", countryCode: "AU"),
            Self.lookupKey(city: "Vientiane", countryCode: "LA"),
            Self.lookupKey(city: "George Town", countryCode: "MY"),
            Self.lookupKey(city: "Karachi", countryCode: "PK"),
            Self.lookupKey(city: "Navoiy", countryCode: "UZ"),
            Self.lookupKey(city: "Tashkent", countryCode: "UZ"),
            Self.lookupKey(city: "Bishkek", countryCode: "KG"),
            Self.lookupKey(city: "Ashgabat", countryCode: "TM"),
            Self.lookupKey(city: "Dushanbe", countryCode: "TJ"),
            Self.lookupKey(city: "Yakutsk", countryCode: "RU"),
            Self.lookupKey(city: "Kuwait City", countryCode: "KW"),
            Self.lookupKey(city: "Manama", countryCode: "BH"),
            Self.lookupKey(city: "Doha", countryCode: "QA"),
            Self.lookupKey(city: "Muscat", countryCode: "OM"),
            Self.lookupKey(city: "Sanaa", countryCode: "YE")
        ]

        #expect(requestedKeys.isSubset(of: cityKeys))
        #expect(requestedKeys.isSubset(of: walkabilityKeys))
    }

    @Test func walkabilityDataCoversEveryCatalogCityUsingNormalizedLookup() throws {
        let cityKeys = try Self.loadCityKeys()
        let walkabilityKeys = try Self.loadWalkabilityKeys()

        #expect(cityKeys.isSubset(of: walkabilityKeys))
    }

    private struct CityRow: Decodable {
        let name: String
        let countryCode: String
    }

    private struct WalkabilityRow: Decodable {
        let city: String
        let countryCode: String
    }

    private static var resourcesDirectory: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(component: "Tourism Beats", directoryHint: .isDirectory)
            .appending(component: "Resources", directoryHint: .isDirectory)
    }

    private static func loadCityKeys() throws -> Set<String> {
        let rows: [CityRow] = try self.decodeJSON(named: "cities.json")
        return Set(rows.map { self.lookupKey(city: $0.name, countryCode: $0.countryCode) })
    }

    private static func loadWalkabilityKeys() throws -> Set<String> {
        let rows: [WalkabilityRow] = try self.decodeJSON(named: "walkability_data.json")
        return Set(rows.map { self.lookupKey(city: $0.city, countryCode: $0.countryCode) })
    }

    private static func decodeJSON<T: Decodable>(named fileName: String) throws -> T {
        let url = self.resourcesDirectory.appending(component: fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func lookupKey(city: String, countryCode: String) -> String {
        let folded = city.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )
        let tokens = folded.unicodeScalars.split { scalar in
            !CharacterSet.alphanumerics.contains(scalar)
        }
        let normalizedCity = tokens.map(String.init).joined(separator: " ")
        return "\(normalizedCity.uppercased())|\(countryCode.uppercased())"
    }
}
