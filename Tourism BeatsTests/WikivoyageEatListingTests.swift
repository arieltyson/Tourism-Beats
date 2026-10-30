import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - WikivoyageEatListingTests

struct WikivoyageEatListingTests {
    private static let porto = """
    ==Eat==
    Porto has some of the finest restaurants in Portugal.

    ===Budget===
    * {{eat
    | name=Café Piolho / Âncora d'Ouro | alt=The Golden Anchor | url=http://www.cafepiolho.com/ | email=
    | address=Praça de Parada Leitão 45 | lat=41.1469 | long=-8.6166 | directions=near the {{station|Aliados}}
    | price={{EUR|7}}
    | content=The third oldest cafe in Porto.
    }}
    ===Splurge===
    * {{eat | name=Cantinho do Avillez | lat=41.1430 | long=-8.6130 | content=Modern Portuguese.}}
    * {{eat | name= | content=A listing without a name.}}
    """

    @Test func readsEveryNamedListingWithItsLocation() {
        let listings = WikivoyageEatListingParser.listings(from: Self.porto)

        #expect(listings.map(\.name) == ["Café Piolho / Âncora d'Ouro", "Cantinho do Avillez"])
        #expect(listings.first?.alternateName == "The Golden Anchor")
        #expect(listings.first?.latitude == 41.1469)
        #expect(listings.last?.longitude == -8.6130)
    }

    @Test(arguments: [
        ("Cantinho do Avillez", 41.1431, -8.6131, true),
        ("CANTINHO DO AVILLEZ", 41.1431, -8.6131, true),
        ("Cantinho do Avillez Porto", 41.1431, -8.6131, true),
        ("Cantinho do Avillez", 41.2000, -8.6131, false),
        ("Cantinho", 41.1431, -8.6131, false)
    ])
    func matchesByNameNearTheListing(name: String, latitude: Double, longitude: Double, matches: Bool) {
        let listing = WikivoyageEatListing(
            name: "Cantinho do Avillez",
            alternateName: nil,
            latitude: 41.1430,
            longitude: -8.6130
        )

        #expect(CityRestaurantWikivoyageService.listing(listing, matches: Self.candidate(name, latitude, longitude)) == matches)
    }

    @Test func matchesTheAlternateName() {
        let listing = WikivoyageEatListing(name: "Âncora d'Ouro", alternateName: "The Golden Anchor", latitude: nil, longitude: nil)

        #expect(CityRestaurantWikivoyageService.listing(listing, matches: Self.candidate("The Golden Anchor", nil, nil)))
    }

    @Test func eitherSideOfASlashSeparatedNameMatches() {
        let listing = WikivoyageEatListing(name: "Café Piolho / Âncora d'Ouro", alternateName: nil, latitude: nil, longitude: nil)

        #expect(CityRestaurantWikivoyageService.listing(listing, matches: Self.candidate("Cafe Piolho", nil, nil)))
        #expect(CityRestaurantWikivoyageService.listing(listing, matches: Self.candidate("Âncora d'Ouro", nil, nil)))
    }

    @Test func shortNamesDoNotMatchByContainment() {
        let listing = WikivoyageEatListing(name: "Bar", alternateName: nil, latitude: nil, longitude: nil)

        #expect(!CityRestaurantWikivoyageService.listing(listing, matches: Self.candidate("Barcelona Tapas", nil, nil)))
    }

    @Test func guideRecommendationLiftsAnEquallyLovedRestaurant() {
        let city = CityModel(
            id: "porto-pt",
            name: "Porto",
            country: CountryModel(name: "Portugal", code: "PT", flag: ""),
            imageURL: URL.documentsDirectory,
            coordinate: .init(latitude: 41.15, longitude: -8.61),
            timeZoneIdentifier: "Europe/Lisbon"
        )
        var picked = Self.candidate("Cantinho do Avillez", nil, nil)
        picked.appleMapsConsensus = 0.4
        picked.isGuideRecommended = true
        var unpicked = Self.candidate("Generic Grill", nil, nil)
        unpicked.appleMapsConsensus = 0.5

        let ranked = CityRestaurantRanking.topRestaurants(from: [unpicked, picked], for: city, limit: 2)

        #expect(ranked.first?.name == "Cantinho do Avillez")
        #expect(ranked.first?.rankingHighlights.contains("Guide Pick") == true)
    }

    private static func candidate(_ name: String, _ latitude: Double?, _ longitude: Double?) -> CityRestaurantCandidate {
        CityRestaurantCandidate(
            id: name,
            name: name,
            cuisine: nil,
            address: nil,
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
            isNotable: false,
            brand: nil,
            popularityRank: nil
        )
    }
}
