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
    /// Apple Maps' identifier for the place, when it came from Apple Maps.
    /// Optional so guides cached before it existed still decode.
    var mapItemIdentifier: String?

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
        GoogleMapsLink.searchURL(for: [self.name, self.address])
    }
}
