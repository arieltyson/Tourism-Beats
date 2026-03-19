import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

struct CityRestaurantRankingTests {
    @Test func rankingPrefersMetadataRichRestaurants() {
        let rankedRestaurants = CityRestaurantRanking.topRestaurants(
            from: [
                self.candidate(
                    id: "sparse",
                    name: "Corner Dining",
                    latitude: 49.281,
                    longitude: -123.118
                ),
                self.candidate(
                    id: "rich",
                    name: "Harvest Table",
                    cuisine: "Pacific Northwest",
                    address: "12 Water Street, Vancouver",
                    hours: "Mo-Su 11:00-22:00",
                    phoneNumber: "+1 604-555-0100",
                    websiteURL: URL(string: "https://harvest.example.com"),
                    latitude: 49.2822,
                    longitude: -123.1174,
                    wheelchairAccessibility: .yes,
                    offersVegetarianOptions: true,
                    hasOutdoorSeating: true,
                    acceptsReservations: true,
                    isNotable: true
                )
            ],
            for: self.city,
            limit: 2
        )

        #expect(rankedRestaurants.first?.name == "Harvest Table")
        #expect(rankedRestaurants.first?.rankingHighlights.contains("Website") == true)
        #expect(rankedRestaurants.first?.rankingHighlights.contains("Notable") == true)
    }

    @Test func rankingBalancesCuisineVarietyAcrossFinalSelection() {
        let rankedRestaurants = CityRestaurantRanking.topRestaurants(
            from: [
                self.candidate(
                    id: "pasta-1",
                    name: "Harbor Pasta",
                    cuisine: "Italian",
                    address: "1 Main Street",
                    hours: "Mo-Su 11:00-22:00",
                    websiteURL: URL(string: "https://harborpasta.example.com"),
                    latitude: 49.2824,
                    longitude: -123.1183
                ),
                self.candidate(
                    id: "pasta-2",
                    name: "Canal Pasta",
                    cuisine: "Italian",
                    address: "2 Main Street",
                    hours: "Mo-Su 11:00-22:00",
                    websiteURL: URL(string: "https://canalpasta.example.com"),
                    latitude: 49.2825,
                    longitude: -123.1182
                ),
                self.candidate(
                    id: "sushi-1",
                    name: "Kumo Sushi",
                    cuisine: "Japanese",
                    address: "3 Main Street",
                    hours: "Mo-Su 12:00-22:00",
                    websiteURL: URL(string: "https://kumosushi.example.com"),
                    latitude: 49.2826,
                    longitude: -123.1181
                )
            ],
            for: self.city,
            limit: 2
        )

        #expect(rankedRestaurants.count == 2)
        #expect(rankedRestaurants.map(\.name).contains("Harbor Pasta"))
        #expect(rankedRestaurants.map(\.name).contains("Kumo Sushi"))
        #expect(!rankedRestaurants.map(\.name).contains("Canal Pasta"))
    }

    @Test func mapsURLUsesCoordinatesWhenAvailable() throws {
        let restaurant = CityRestaurant(
            id: "maps",
            name: "Signal Kitchen",
            cuisine: "Contemporary",
            summary: "Test",
            address: "4 Main Street, Vancouver",
            hours: nil,
            phoneNumber: nil,
            websiteURL: nil,
            sourceURL: nil,
            sourceName: "OpenStreetMap",
            latitude: 49.2827,
            longitude: -123.1207,
            wheelchairAccessibility: .unknown,
            offersVegetarianOptions: false,
            offersVeganOptions: false,
            hasOutdoorSeating: false,
            acceptsReservations: false,
            rankingScore: 0,
            rankingHighlights: []
        )

        let mapsURL = try #require(restaurant.mapsURL)
        let components = try #require(
            URLComponents(url: mapsURL, resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map {
                ($0.name, $0.value ?? "")
            }
        )

        #expect(components.host == "maps.apple.com")
        #expect(queryItems["q"] == "Signal Kitchen")
        #expect(queryItems["ll"] == "49.2827,-123.1207")
    }

    private var city: CityModel {
        CityModel(
            id: "vancouver-ca",
            name: "Vancouver",
            country: CountryModel(name: "Canada", code: "CA", flag: "🇨🇦"),
            imageURL: URL(string: "https://example.com/city.jpg")!,
            coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            timeZoneIdentifier: "America/Vancouver"
        )
    }

    private func candidate(
        id: String,
        name: String,
        cuisine: String? = nil,
        address: String? = nil,
        hours: String? = nil,
        phoneNumber: String? = nil,
        websiteURL: URL? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        wheelchairAccessibility: CityRestaurant.AccessibilityLevel = .unknown,
        offersVegetarianOptions: Bool = false,
        offersVeganOptions: Bool = false,
        hasOutdoorSeating: Bool = false,
        acceptsReservations: Bool = false,
        isNotable: Bool = false
    ) -> CityRestaurantCandidate {
        CityRestaurantCandidate(
            id: id,
            name: name,
            cuisine: cuisine,
            address: address,
            hours: hours,
            phoneNumber: phoneNumber,
            websiteURL: websiteURL,
            sourceURL: URL(string: "https://example.com/\(id)"),
            sourceName: "OpenStreetMap",
            latitude: latitude,
            longitude: longitude,
            wheelchairAccessibility: wheelchairAccessibility,
            offersVegetarianOptions: offersVegetarianOptions,
            offersVeganOptions: offersVeganOptions,
            hasOutdoorSeating: hasOutdoorSeating,
            acceptsReservations: acceptsReservations,
            isNotable: isNotable,
            brand: nil
        )
    }
}
