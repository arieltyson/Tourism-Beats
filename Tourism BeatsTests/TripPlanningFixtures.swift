import CoreLocation
import Foundation
@testable import Tourism_Beats

/// Shared city, activity, and restaurant fixtures for trip planning tests.
enum TripPlanningFixtures {
    static let portOfSpain = CityModel(
        id: "port-of-spain-tt",
        name: "Port of Spain",
        country: CountryModel(name: "Trinidad and Tobago", code: "TT", flag: "🇹🇹"),
        imageURL: URL(string: "https://example.com/port-of-spain.jpg")!,
        coordinate: CLLocationCoordinate2D(latitude: 10.6596, longitude: -61.5089),
        timeZoneIdentifier: "America/Port_of_Spain"
    )

    static func activity(
        _ name: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        category: String = "Landmark",
        timingTip: String? = nil
    ) -> CityActivity {
        CityActivity(
            id: name.lowercased().replacing(" ", with: "_"),
            name: name,
            summary: "\(name) summary.",
            category: category,
            kind: .see,
            imageURL: nil,
            officialURL: nil,
            sourceURL: nil,
            sourceName: "Wikivoyage",
            hours: nil,
            price: nil,
            address: "\(name) Road",
            directions: nil,
            timingTip: timingTip,
            latitude: latitude,
            longitude: longitude,
            wikidataIdentifier: nil,
            sourcePageTitle: nil,
            sourceAnchor: nil
        )
    }

    static func restaurant(
        _ name: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        cuisine: String? = "Caribbean"
    ) -> CityRestaurant {
        CityRestaurant(
            id: "restaurant_\(name.lowercased().replacing(" ", with: "_"))",
            name: name,
            cuisine: cuisine,
            summary: "\(name) summary.",
            address: "\(name) Street",
            hours: nil,
            phoneNumber: nil,
            websiteURL: nil,
            sourceURL: nil,
            sourceName: "Apple Maps",
            latitude: latitude,
            longitude: longitude,
            wheelchairAccessibility: .unknown,
            offersVegetarianOptions: false,
            offersVeganOptions: false,
            hasOutdoorSeating: false,
            acceptsReservations: false,
            rankingScore: 0,
            rankingHighlights: []
        )
    }

    static func activities(count: Int) -> [CityActivity] {
        (1 ... count).map { self.activity("Sight \($0)") }
    }

    static func restaurants(count: Int) -> [CityRestaurant] {
        (1 ... count).map { self.restaurant("Kitchen \($0)") }
    }
}
