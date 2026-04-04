import CoreLocation
import Foundation

// MARK: - Apple Maps Fallback Summaries

extension CityActivityService {
    static func cleanedMapKitAddress(_ address: String?) -> String? {
        guard let address = address?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty
        else {
            return nil
        }

        let cleaned = address
            .replacingOccurrences(
                of: #"\s*\|\s*"#,
                with: ", ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #",\s*,+"#,
                with: ", ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"\s{2,}"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(
                in: CharacterSet(charactersIn: ",| ").union(.whitespacesAndNewlines)
            )

        return cleaned.isEmpty ? nil : cleaned
    }

    static func mapKitSummary(
        for result: Models.MapKitActivityResult,
        city: CityModel,
        categoryResult: Models.CategoryResult
    ) -> String {
        let descriptor = self.mapKitDescriptor(
            for: result.name,
            category: categoryResult.category,
            kind: categoryResult.kind
        )

        var leadSentence = "A \(descriptor) in \(city.name), \(city.country.name)"
        if let locationPhrase = self.mapKitLocationPhrase(for: result, city: city) {
            leadSentence += " \(locationPhrase)"
        }
        leadSentence += "."

        return "\(leadSentence) \(self.mapKitDemandPhrase(for: result))"
    }

    private static func mapKitDescriptor(
        for name: String,
        category: String,
        kind: CityActivity.Kind
    ) -> String {
        let normalizedName = CityActivityRanking.activityKey(for: name)

        let keywordDescriptors: [(String, String)] = [
            ("museum", "museum"),
            ("gallery", "gallery"),
            ("theatre", "theatre"),
            ("theater", "theatre"),
            ("opera", "performance venue"),
            ("cathedral", "religious landmark"),
            ("church", "religious landmark"),
            ("mosque", "religious landmark"),
            ("temple", "religious landmark"),
            ("synagogue", "religious landmark"),
            ("palace", "historic landmark"),
            ("castle", "historic landmark"),
            ("fort", "historic landmark"),
            ("fortress", "historic landmark"),
            ("bridge", "landmark bridge"),
            ("square", "public square"),
            ("plaza", "public square"),
            ("park", "park"),
            ("garden", "garden"),
            ("market", "market"),
            ("bazaar", "market"),
            ("zoo", "zoo"),
            ("aquarium", "aquarium"),
            ("tower", "viewpoint"),
            ("memorial", "memorial"),
            ("monument", "monument"),
            ("stadium", "stadium"),
            ("library", "library"),
            ("beach", "beachfront stop")
        ]

        if let descriptor = keywordDescriptors.first(where: { keyword, _ in
            normalizedName.localizedStandardContains(keyword)
        })?.1 {
            return descriptor
        }

        return switch CityActivityRanking.activityKey(for: category) {
        case "museum":
            "museum"
        case "gallery":
            "gallery"
        case "heritage":
            "heritage site"
        case "landmark":
            "landmark"
        case "nature":
            "nature stop"
        case "architecture":
            "architectural site"
        case "entertainment":
            "performance venue"
        case "attraction":
            kind == .do ? "local experience" : "visitor attraction"
        default:
            "\(category.lowercased()) attraction"
        }
    }

    private static func mapKitLocationPhrase(
        for result: Models.MapKitActivityResult,
        city: CityModel
    ) -> String? {
        if let addressFragment = self.mapKitAddressFragment(
            from: result.address,
            city: city
        ) {
            let preposition = self.mapKitAddressUsesOnPreposition(addressFragment)
                ? "on"
                : "near"
            return "\(preposition) \(addressFragment)"
        }

        guard let distance = CityActivityRanking.distance(
            from: city.coordinate,
            latitude: result.latitude,
            longitude: result.longitude
        ) else {
            return nil
        }

        if distance <= 2_000 {
            return "close to the city center"
        }

        return nil
    }

    private static func mapKitAddressFragment(
        from address: String?,
        city: CityModel
    ) -> String? {
        guard let cleanedAddress = self.cleanedMapKitAddress(address) else {
            return nil
        }

        let cityKey = CityActivityRanking.activityKey(for: city.name)
        let countryKey = CityActivityRanking.activityKey(for: city.country.name)

        let components = cleanedAddress
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let filteredComponents = components.filter { component in
            let key = CityActivityRanking.activityKey(for: component)
            return !key.isEmpty && key != cityKey && key != countryKey
        }

        if let firstMeaningfulComponent = filteredComponents.first {
            return firstMeaningfulComponent
        }

        return nil
    }

    private static func mapKitAddressUsesOnPreposition(_ value: String) -> Bool {
        let normalizedValue = CityActivityRanking.activityKey(for: value)
        let onKeywords = [
            "street",
            "st",
            "road",
            "rd",
            "avenue",
            "ave",
            "boulevard",
            "blvd",
            "square",
            "sq",
            "place",
            "pl",
            "drive",
            "dr",
            "lane",
            "ln",
            "way",
            "wharf",
            "quay",
            "embankment"
        ]

        if onKeywords.contains(where: { normalizedValue.localizedStandardContains($0) }) {
            return true
        }

        return value.contains(where: \.isNumber)
    }

    private static func mapKitDemandPhrase(
        for result: Models.MapKitActivityResult
    ) -> String {
        if result.reviewQueryAppearanceCount >= 3 {
            return "It ranks strongly across best-of and top-rated attraction searches for the city."
        }

        if result.crossQueryAppearanceCount >= 4 {
            return "It appears repeatedly across popular attraction searches for the city."
        }

        if result.popularityRank <= 3 {
            return "It is one of the stronger attraction matches for the city."
        }

        return "It surfaced as a useful visitor stop for the city."
    }
}
