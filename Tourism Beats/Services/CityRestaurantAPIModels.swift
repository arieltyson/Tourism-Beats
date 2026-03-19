import Foundation

// MARK: - CityRestaurantService Response Models

enum CityRestaurantAPIModels {
    struct OverpassResponse: Decodable {
        let elements: [OverpassElement]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.elements = (try? container.decode([OverpassElement].self, forKey: .elements)) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case elements
        }
    }

    struct OverpassElement: Decodable {
        let type: String?
        let id: Int?
        let lat: Double?
        let lon: Double?
        let center: OverpassCenter?
        let tags: OverpassTags?
    }

    struct OverpassCenter: Decodable {
        let lat: Double
        let lon: Double
    }

    struct OverpassTags: Decodable {
        let name: String?
        let amenity: String?
        let cuisine: String?
        let website: String?
        let contactWebsite: String?
        let phone: String?
        let contactPhone: String?
        let openingHours: String?
        let wikidata: String?
        let brand: String?
        let wheelchair: String?
        let outdoorSeating: String?
        let reservation: String?
        let dietVegetarian: String?
        let dietVegan: String?
        let addrStreet: String?
        let addrHousenumber: String?
        let addrCity: String?

        private enum CodingKeys: String, CodingKey {
            case name
            case amenity
            case cuisine
            case website
            case contactWebsite = "contact:website"
            case phone
            case contactPhone = "contact:phone"
            case openingHours = "opening_hours"
            case wikidata
            case brand
            case wheelchair
            case outdoorSeating = "outdoor_seating"
            case reservation
            case dietVegetarian = "diet:vegetarian"
            case dietVegan = "diet:vegan"
            case addrStreet = "addr:street"
            case addrHousenumber = "addr:housenumber"
            case addrCity = "addr:city"
        }
    }

    struct OverpassRestaurant: Sendable {
        let elementType: String?
        let elementIdentifier: Int?
        let name: String
        let latitude: Double?
        let longitude: Double?
        let cuisine: String?
        let website: URL?
        let phoneNumber: String?
        let openingHours: String?
        let address: String?
        let brand: String?
        let wheelchairAccessibility: CityRestaurant.AccessibilityLevel
        let offersVegetarianOptions: Bool
        let offersVeganOptions: Bool
        let hasOutdoorSeating: Bool
        let acceptsReservations: Bool
        let isNotable: Bool
    }

    struct CachedPayload: Codable, Sendable {
        let fetchedAt: Date
        let restaurants: [CityRestaurant]

        func isValid(lifetime: TimeInterval) -> Bool {
            self.fetchedAt.addingTimeInterval(lifetime) > .now
        }
    }

    struct MapKitRestaurantResult: Sendable {
        let name: String
        let phoneNumber: String?
        let websiteURL: URL?
        let address: String?
        let latitude: Double
        let longitude: Double
        let popularityRank: Int
    }

    enum ServiceError: Error {
        case invalidResponse
        case invalidRequest
        case httpStatus(Int)
    }
}
