import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - CityActivityServiceEnrichmentTests

struct CityActivityServiceEnrichmentTests {
    @Test func enrichFallbackActivitiesIfNeededUsesWikipediaSummaryForSelectedFallbacks() async throws {
        let service = CityActivityService(
            session: .shared,
            wikipediaSummaryService: StubWikipediaSummaryProvider(
                summariesByTitle: [
                    "Royal Palace of Brussels": WikipediaSummary(
                        title: "Royal Palace of Brussels",
                        description: "Palace in Brussels, Belgium",
                        extract: """
                        The Royal Palace of Brussels is the official palace of the Belgian monarch in the center of Brussels.
                        """,
                        thumbnailURL: URL(string: "https://example.com/palace-thumb.jpg"),
                        originalImageURL: URL(string: "https://example.com/palace.jpg"),
                        articleURL: URL(string: "https://en.wikipedia.org/wiki/Royal_Palace_of_Brussels")
                    )
                ]
            )
        )

        let city = CityModel(
            id: "brussels-be",
            name: "Brussels",
            country: CountryModel(name: "Belgium", code: "BE", flag: "🇧🇪"),
            imageURL: URL(string: "https://example.com/brussels.jpg")!,
            coordinate: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517),
            timeZoneIdentifier: "Europe/Brussels"
        )

        let activities = [
            CityActivity(
                id: "palace",
                name: "Royal Palace of Brussels",
                summary: "A historic landmark in Brussels, Belgium on Rue Brederode 16. It is one of the stronger attraction matches for the city.",
                category: "Heritage",
                kind: .see,
                imageURL: nil,
                officialURL: URL(string: "https://www.monarchie.be/en"),
                sourceURL: nil,
                sourceName: "Apple Maps",
                hours: nil,
                price: nil,
                address: "Rue Brederode 16, Brussels",
                directions: nil,
                timingTip: nil,
                latitude: 50.8433,
                longitude: 4.3600,
                wikidataIdentifier: nil,
                sourcePageTitle: nil,
                sourceAnchor: nil
            ),
            CityActivity(
                id: "museum",
                name: "Magritte Museum",
                summary: "A major Brussels museum with a broad collection dedicated to Rene Magritte.",
                category: "Museum",
                kind: .see,
                imageURL: URL(string: "https://example.com/magritte.jpg"),
                officialURL: nil,
                sourceURL: URL(string: "https://example.com/magritte"),
                sourceName: "Wikivoyage",
                hours: nil,
                price: nil,
                address: "Place Royale 1, Brussels",
                directions: nil,
                timingTip: nil,
                latitude: 50.8426,
                longitude: 4.3570,
                wikidataIdentifier: nil,
                sourcePageTitle: "Magritte Museum",
                sourceAnchor: nil
            )
        ]

        let enrichedActivities = await service.enrichFallbackActivitiesIfNeeded(
            activities,
            for: city
        )

        let palace = try #require(enrichedActivities.first)
        #expect(
            palace.summary == "The Royal Palace of Brussels is the official palace of the Belgian monarch in the center of Brussels."
        )
        #expect(palace.imageURL == URL(string: "https://example.com/palace.jpg"))
        #expect(
            palace.sourceURL == URL(string: "https://en.wikipedia.org/wiki/Royal_Palace_of_Brussels")
        )
        #expect(palace.sourcePageTitle == "Royal Palace of Brussels")

        let museum = try #require(enrichedActivities.last)
        #expect(museum.summary == activities[1].summary)
        #expect(museum.imageURL == activities[1].imageURL)
    }
}

// MARK: - StubWikipediaSummaryProvider

private struct StubWikipediaSummaryProvider: WikipediaSummaryProviding {
    let summariesByTitle: [String: WikipediaSummary]

    func summary(for title: String, near _: String) async -> WikipediaSummary? {
        self.summariesByTitle[title]
    }
}
