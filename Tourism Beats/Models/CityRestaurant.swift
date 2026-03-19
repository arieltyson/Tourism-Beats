import Foundation

struct CityRestaurant: Identifiable, Hashable, Codable, Sendable {
    enum AccessibilityLevel: String, Codable, Sendable {
        case yes
        case limited
        case no
        case unknown

        var label: String {
            switch self {
            case .yes:
                "Wheelchair Accessible"
            case .limited:
                "Limited Accessibility"
            case .no:
                "Accessibility Not Listed"
            case .unknown:
                "Accessibility Unknown"
            }
        }

        var detailLabel: String {
            switch self {
            case .yes:
                "Wheelchair access listed"
            case .limited:
                "Limited wheelchair access listed"
            case .no:
                "No wheelchair access listed"
            case .unknown:
                "Accessibility not listed"
            }
        }
    }

    let id: String
    let name: String
    let cuisine: String?
    let summary: String
    let address: String?
    let hours: String?
    let phoneNumber: String?
    let websiteURL: URL?
    let sourceURL: URL?
    let sourceName: String
    let latitude: Double?
    let longitude: Double?
    let wheelchairAccessibility: AccessibilityLevel
    let offersVegetarianOptions: Bool
    let offersVeganOptions: Bool
    let hasOutdoorSeating: Bool
    let acceptsReservations: Bool
    let rankingScore: Int
    let rankingHighlights: [String]

    var displayCuisine: String {
        self.cuisine ?? "Restaurant"
    }

    var dietarySummary: String? {
        switch (self.offersVegetarianOptions, self.offersVeganOptions) {
        case (true, true):
            "Vegetarian and vegan options listed"
        case (true, false):
            "Vegetarian options listed"
        case (false, true):
            "Vegan options listed"
        case (false, false):
            nil
        }
    }

    var mapsURL: URL? {
        let query = [self.name, self.address]
            .compactMap { value in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .joined(separator: ", ")

        guard !query.isEmpty else { return nil }

        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }
}
