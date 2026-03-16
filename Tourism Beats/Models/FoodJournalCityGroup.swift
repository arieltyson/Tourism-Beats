import Foundation

struct FoodJournalCityGroup: Identifiable, Hashable {
    let key: String
    let rawCityName: String
    let rawCountryName: String
    let restaurantCount: Int
    let city: CityModel?

    var id: String { self.key }

    var displayCityName: String {
        self.city?.name ?? self.rawCityName
    }

    var displayCountryName: String {
        if let city = self.city {
            return city.country.name
        }
        return self.rawCountryName
    }

    var imageURL: URL? {
        self.city?.imageURL
    }

    var accessibilityLabel: String {
        let cityName = self.displayCityName
        let countryName = self.displayCountryName
        let restaurantLabel = self.restaurantCount == 1
            ? "1 saved restaurant"
            : "\(self.restaurantCount.formatted(.number)) saved restaurants"

        guard !countryName.isEmpty else {
            return "\(cityName), \(restaurantLabel)"
        }

        return "\(cityName), \(countryName), \(restaurantLabel)"
    }

    func contains(_ restaurant: Restaurant) -> Bool {
        Self.groupKey(city: restaurant.city, country: restaurant.country) == self.key
    }

    static func groupKey(city: String, country: String) -> String {
        "\(self.normalizedLookupValue(city))|\(self.normalizedLookupValue(country))"
    }

    static func normalizedLookupValue(_ value: String) -> String {
        let folded = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )

        let collapsed = String(
            folded.unicodeScalars.map { scalar in
                CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
            }
        )

        return collapsed
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
