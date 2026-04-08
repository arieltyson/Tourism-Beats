import Foundation
import Testing

struct CityCatalogCoverageTests {
    @Test func requestedCitiesArePresentWithWalkabilityCoverage() throws {
        let cityKeys = try Self.loadCityKeys()
        let walkabilityKeys = try Self.loadWalkabilityKeys()
        let requestedKeys: Set<String> = [
            Self.lookupKey(city: "Ouagadougou", countryCode: "BF"),
            Self.lookupKey(city: "Bandar Seri Begawan", countryCode: "BN"),
            Self.lookupKey(city: "Monrovia", countryCode: "LR"),
            Self.lookupKey(city: "Conakry", countryCode: "GN"),
            Self.lookupKey(city: "Bissau", countryCode: "GW"),
            Self.lookupKey(city: "Bamako", countryCode: "ML"),
            Self.lookupKey(city: "Porto-Novo", countryCode: "BJ"),
            Self.lookupKey(city: "Niamey", countryCode: "NE"),
            Self.lookupKey(city: "N'Djamena", countryCode: "TD"),
            Self.lookupKey(city: "Kigali", countryCode: "RW"),
            Self.lookupKey(city: "Bujumbura", countryCode: "BI"),
            Self.lookupKey(city: "Lilongwe", countryCode: "MW"),
            Self.lookupKey(city: "Mbabane", countryCode: "SZ"),
            Self.lookupKey(city: "Windhoek", countryCode: "NA"),
            Self.lookupKey(city: "Kinshasa", countryCode: "CD"),
            Self.lookupKey(city: "Bangui", countryCode: "CF"),
            Self.lookupKey(city: "Juba", countryCode: "SS"),
            Self.lookupKey(city: "Perth", countryCode: "AU"),
            Self.lookupKey(city: "Adelaide", countryCode: "AU"),
            Self.lookupKey(city: "Jayapura", countryCode: "ID"),
            Self.lookupKey(city: "Shenzhen", countryCode: "CN"),
            Self.lookupKey(city: "Chongqing", countryCode: "CN"),
            Self.lookupKey(city: "Xi'an", countryCode: "CN"),
            Self.lookupKey(city: "Chengdu", countryCode: "CN"),
            Self.lookupKey(city: "Kunming", countryCode: "CN"),
            Self.lookupKey(city: "Almaty", countryCode: "KZ"),
            Self.lookupKey(city: "Kabul", countryCode: "AF"),
            Self.lookupKey(city: "Kobe", countryCode: "JP"),
            Self.lookupKey(city: "Osaka", countryCode: "JP"),
            Self.lookupKey(city: "Sapporo", countryCode: "JP"),
            Self.lookupKey(city: "Fukuoka", countryCode: "JP"),
            Self.lookupKey(city: "Phnom Penh", countryCode: "KH"),
            Self.lookupKey(city: "Kolkata", countryCode: "IN"),
            Self.lookupKey(city: "Medellin", countryCode: "CO"),
            Self.lookupKey(city: "Hanoi", countryCode: "VN"),
            Self.lookupKey(city: "Cluj-Napoca", countryCode: "RO"),
            Self.lookupKey(city: "Brasov", countryCode: "RO"),
            Self.lookupKey(city: "Venice", countryCode: "IT"),
            Self.lookupKey(city: "Cancun", countryCode: "MX"),
            Self.lookupKey(city: "Whistler", countryCode: "CA"),
            Self.lookupKey(city: "Bora-Bora", countryCode: "PF"),
            Self.lookupKey(city: "Male", countryCode: "MV"),
            Self.lookupKey(city: "Orimasvaru", countryCode: "MV"),
            Self.lookupKey(city: "Jerusalem", countryCode: "IL"),
            Self.lookupKey(city: "Kyoto", countryCode: "JP"),
            Self.lookupKey(city: "Tucson", countryCode: "US"),
            Self.lookupKey(city: "Merida", countryCode: "MX"),
            Self.lookupKey(city: "Port Louis", countryCode: "MU"),
            Self.lookupKey(city: "Fira", countryCode: "GR"),
            Self.lookupKey(city: "Honolulu", countryCode: "US"),
            Self.lookupKey(city: "Maui", countryCode: "US"),
            Self.lookupKey(city: "Amman", countryCode: "JO"),
            Self.lookupKey(city: "Banff", countryCode: "CA"),
            Self.lookupKey(city: "Torshavn", countryCode: "FO"),
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
            Self.lookupKey(city: "Sanaa", countryCode: "YE"),
            Self.lookupKey(city: "Florence", countryCode: "IT"),
            Self.lookupKey(city: "Saint-Tropez", countryCode: "FR"),
            Self.lookupKey(city: "Tallinn", countryCode: "EE"),
            Self.lookupKey(city: "Riga", countryCode: "LV"),
            Self.lookupKey(city: "Vilnius", countryCode: "LT"),
            Self.lookupKey(city: "Minsk", countryCode: "BY")
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
