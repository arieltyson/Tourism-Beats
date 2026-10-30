import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - WikipediaArticleLocationVerifierTests

struct WikipediaArticleLocationVerifierTests {
    private static let clujNapoca = CityModel(
        id: "cluj-napoca-ro",
        name: "Cluj-Napoca",
        country: CountryModel(name: "Romania", code: "RO", flag: "🇷🇴"),
        imageURL: URL.documentsDirectory,
        coordinate: CLLocationCoordinate2D(latitude: 46.7712, longitude: 23.6236),
        timeZoneIdentifier: "Europe/Bucharest"
    )

    private static let newYorkCentralPark = WikipediaSummary(
        title: "Central Park",
        description: "Urban park in Manhattan, New York City",
        extract: "Central Park is an urban park between the Upper West Side and Upper East Side of Manhattan.",
        thumbnailURL: nil,
        originalImageURL: nil,
        articleURL: nil,
        latitude: 40.7825,
        longitude: -73.9658
    )

    @Test func rejectsSameNamedArticleFromAnotherCity() {
        let context = WikipediaLookupContext(
            city: Self.clujNapoca,
            placeLatitude: 46.7689,
            placeLongitude: 23.5793
        )

        #expect(!WikipediaArticleLocationVerifier.isArticle(Self.newYorkCentralPark, about: context))
    }

    @Test func rejectsArticleFarFromCityWhenPlaceLocationIsUnknown() {
        let context = WikipediaLookupContext(city: Self.clujNapoca)

        #expect(!WikipediaArticleLocationVerifier.isArticle(Self.newYorkCentralPark, about: context))
    }

    @Test func acceptsArticleAtThePlace() {
        let context = WikipediaLookupContext(
            city: Self.clujNapoca,
            placeLatitude: 46.7689,
            placeLongitude: 23.5793
        )
        let summary = Self.summary(latitude: 46.7695, longitude: 23.5800)

        #expect(WikipediaArticleLocationVerifier.isArticle(summary, about: context))
    }

    @Test func rejectsArticleInTheCityButFarFromAKnownPlace() {
        let context = WikipediaLookupContext(city: Self.clujNapoca, placeLatitude: 46.77, placeLongitude: 23.58)
        let tooFar = WikipediaArticleLocationVerifier.maximumDistanceFromPlace + 1_000
        let shiftedLatitude = 46.77 + tooFar / 111_000
        let summary = Self.summary(latitude: shiftedLatitude, longitude: 23.58)

        #expect(!WikipediaArticleLocationVerifier.isArticle(summary, about: context))
    }

    @Test func acceptsArticleNearTheCityWhenPlaceLocationIsUnknown() {
        let context = WikipediaLookupContext(city: Self.clujNapoca)
        let summary = Self.summary(latitude: 46.80, longitude: 23.70)

        #expect(WikipediaArticleLocationVerifier.isArticle(summary, about: context))
    }

    @Test func articleWithoutCoordinatesMustNameTheCity() {
        let context = WikipediaLookupContext(city: Self.clujNapoca)
        let local = Self.summary(extract: "The festival is held every summer in Cluj-Napoca, Romania.")
        let elsewhere = Self.summary(extract: "The festival is held every summer in Bucharest, Romania.")

        #expect(WikipediaArticleLocationVerifier.isArticle(local, about: context))
        #expect(!WikipediaArticleLocationVerifier.isArticle(elsewhere, about: context))
    }

    @Test(arguments: [
        ("Held in Nice, France.", "Nice", true),
        ("Enjoy a nice view of the bay.", "Nice", false),
        ("Founded in Cluj Napoca in 1581.", "Cluj-Napoca", true),
        ("A museum in São Paulo.", "Sao Paulo", true),
        ("A suburb of Parisville.", "Paris", false)
    ])
    func cityNameMatchesWholeWordsOnly(text: String, name: String, matches: Bool) {
        #expect(WikipediaArticleLocationVerifier.text(text, mentions: name) == matches)
    }

    private static func summary(
        extract: String = "A park in the city centre.",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> WikipediaSummary {
        WikipediaSummary(
            title: "Central Park",
            description: nil,
            extract: extract,
            thumbnailURL: nil,
            originalImageURL: nil,
            articleURL: nil,
            latitude: latitude,
            longitude: longitude
        )
    }
}
