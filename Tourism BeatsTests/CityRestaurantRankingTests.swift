import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

struct CityRestaurantRankingTests {
    @Test func rankingPrefersPopularAndNotableRestaurants() {
        let rankedRestaurants = CityRestaurantRanking.topRestaurants(
            from: [
                self.candidate(
                    id: "unpopular",
                    name: "Corner Dining",
                    latitude: 49.281,
                    longitude: -123.118,
                    popularityRank: 25
                ),
                self.candidate(
                    id: "popular",
                    name: "Harvest Table",
                    cuisine: "Pacific Northwest",
                    address: "12 Water Street, Vancouver",
                    websiteURL: URL(string: "https://harvest.example.com"),
                    latitude: 49.2822,
                    longitude: -123.1174,
                    isNotable: true,
                    popularityRank: 1
                )
            ],
            for: self.city,
            limit: 2
        )

        #expect(rankedRestaurants.first?.name == "Harvest Table")
        #expect(rankedRestaurants.first?.rankingHighlights.contains("Popular") == true)
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
                    websiteURL: URL(string: "https://harborpasta.example.com"),
                    latitude: 49.2824,
                    longitude: -123.1183,
                    popularityRank: 1
                )
                .with { $0.appleMapsConsensus = 0.6 },
                self.candidate(
                    id: "pasta-2",
                    name: "Canal Pasta",
                    cuisine: "Italian",
                    address: "2 Main Street",
                    websiteURL: URL(string: "https://canalpasta.example.com"),
                    latitude: 49.2825,
                    longitude: -123.1182,
                    popularityRank: 2
                )
                .with { $0.appleMapsConsensus = 0.55 },
                self.candidate(
                    id: "sushi-1",
                    name: "Kumo Sushi",
                    cuisine: "Japanese",
                    address: "3 Main Street",
                    websiteURL: URL(string: "https://kumosushi.example.com"),
                    latitude: 49.2826,
                    longitude: -123.1181,
                    popularityRank: 3
                )
                .with { $0.appleMapsConsensus = 0.5 }
            ],
            for: self.city,
            limit: 2
        )

        #expect(rankedRestaurants.count == 2)
        #expect(rankedRestaurants.map(\.name).contains("Harbor Pasta"))
        #expect(rankedRestaurants.map(\.name).contains("Kumo Sushi"))
        #expect(!rankedRestaurants.map(\.name).contains("Canal Pasta"))
    }

    /// A place Apple Maps keeps near the top of its searches is the best free
    /// stand-in for a highly rated, widely reviewed restaurant, and must not
    /// lose to a lesser one that is merely better documented.
    @Test func consistentlyTopRankedRestaurantBeatsBetterDocumentedOne() {
        let loved = self.candidate(id: "loved", name: "Quiet Kitchen", popularityRank: 2)
            .with { $0.appleMapsConsensus = 0.8 }
        let documented = self.candidate(
            id: "documented",
            name: "Busy Corner",
            cuisine: "Bistro",
            websiteURL: URL(string: "https://corner.example.com"),
            latitude: 49.2827,
            longitude: -123.1207,
            isNotable: true,
            popularityRank: 9
        )
        .with {
            $0.appleMapsConsensus = 0.2
            $0.metadataRichnessScore = 30
        }

        let ranked = CityRestaurantRanking.topRestaurants(from: [documented, loved], for: self.city, limit: 2)

        #expect(ranked.map(\.name) == ["Quiet Kitchen", "Busy Corner"])
    }

    @Test func michelinRecognitionLiftsAnEquallyLovedRestaurant() {
        let starred = self.candidate(id: "starred", name: "Étoile", popularityRank: 4)
            .with {
                $0.appleMapsConsensus = 0.5
                $0.isMichelinRecognized = true
            }
        let unstarred = self.candidate(id: "unstarred", name: "Plain Plate", popularityRank: 3)
            .with { $0.appleMapsConsensus = 0.55 }

        let ranked = CityRestaurantRanking.topRestaurants(from: [unstarred, starred], for: self.city, limit: 2)

        #expect(ranked.first?.name == "Étoile")
        #expect(ranked.first?.rankingHighlights.contains("Award-Winning") == true)
    }

    @Test func expertRecognitionAloneDoesNotOutrankTheCrowdsFavourite() {
        let crowdFavourite = self.candidate(id: "favourite", name: "Night Market Grill", popularityRank: 1)
            .with { $0.appleMapsConsensus = 0.9 }
        let obscureStar = self.candidate(id: "obscure", name: "Hidden Salon", popularityRank: 20)
            .with {
                $0.appleMapsConsensus = 0.1
                $0.isMichelinRecognized = true
            }

        let ranked = CityRestaurantRanking.topRestaurants(from: [obscureStar, crowdFavourite], for: self.city, limit: 2)

        #expect(ranked.first?.name == "Night Market Grill")
    }

    @Test func restaurantsWithoutEvidenceOfQualityAreLeftOut() {
        let loved = self.candidate(id: "loved", name: "Lantern House", popularityRank: 1)
            .with { $0.appleMapsConsensus = 0.7 }
        let barelySeen = self.candidate(id: "barely", name: "Side Street Diner", popularityRank: 24)
            .with { $0.appleMapsConsensus = 0.12 }
        let guidePick = self.candidate(id: "pick", name: "Old Port Tavern", popularityRank: 30)
            .with {
                $0.appleMapsConsensus = 0.02
                $0.isGuideRecommended = true
            }

        let ranked = CityRestaurantRanking.topRestaurants(
            from: [barelySeen, guidePick, loved],
            for: self.city,
            limit: 6
        )

        #expect(Set(ranked.map(\.name)) == ["Lantern House", "Old Port Tavern"])
    }

    @Test func aCityWithoutEvidenceStillShowsItsBestRestaurants() {
        let mapDataOnly = ["Fjord Café", "Harbour Kitchen"].map {
            self.candidate(id: $0, name: $0, cuisine: "Nordic")
        }

        let ranked = CityRestaurantRanking.topRestaurants(from: mapDataOnly, for: self.city, limit: 6)

        #expect(ranked.count == 2)
    }

    @Test(arguments: [(0.12, 0.4, true), (0.12, 0.6, false), (0.08, 0.2, false)])
    func consensusMustBeMeaningfulAndCloseEnoughToTheBest(consensus: Double, strongest: Double, qualifies: Bool) {
        let candidate = self.candidate(id: "c", name: "Candidate").with { $0.appleMapsConsensus = consensus }

        #expect(CityRestaurantRanking.hasQualityEvidence(candidate, strongestConsensus: strongest) == qualifies)
    }

    @Test func mapsURLUsesGoogleMapsWithCoordinates() throws {
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
            sourceName: "Apple Maps",
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

        #expect(components.host == "www.google.com")
        #expect(queryItems["api"] == "1")
        #expect(queryItems["query"] == "Signal Kitchen, 4 Main Street, Vancouver")
    }

    private var city: CityModel {
        CityModel(
            id: "vancouver-ca",
            name: "Vancouver",
            country: CountryModel(name: "Canada", code: "CA", flag: "\u{1f1e8}\u{1f1e6}"),
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
        isNotable: Bool = false,
        popularityRank: Int? = nil
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
            sourceName: "Apple Maps",
            latitude: latitude,
            longitude: longitude,
            wheelchairAccessibility: wheelchairAccessibility,
            offersVegetarianOptions: offersVegetarianOptions,
            offersVeganOptions: offersVeganOptions,
            hasOutdoorSeating: hasOutdoorSeating,
            acceptsReservations: acceptsReservations,
            isNotable: isNotable,
            brand: nil,
            popularityRank: popularityRank
        )
    }
}

// MARK: - Test Helpers

private extension CityRestaurantCandidate {
    func with(_ change: (inout CityRestaurantCandidate) -> Void) -> CityRestaurantCandidate {
        var copy = self
        change(&copy)
        return copy
    }
}
