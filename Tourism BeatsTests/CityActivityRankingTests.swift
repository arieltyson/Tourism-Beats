import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

struct CityActivityRankingTests {
    @Test func topActivitiesPrefersDemandSignalsOverMetadataAlone() throws {
        let demandSignals = [
            CityActivityRanking.activityKey(for: "Royal Palace"): CityActivityRanking.ActivityDemandSignal(
                popularityRank: 1,
                crossQueryAppearanceCount: 5,
                reviewQueryAppearanceCount: 2,
                pageviewCount: 920_000,
                pageviewRank: 1
            )
        ]

        let rankedActivities = CityActivityRanking.topActivities(
            from: [
                self.activity(
                    id: "sculpture",
                    name: "City Sculpture Garden",
                    summary: "A collection of public sculptures on the riverfront with seasonal installations.",
                    category: "Art",
                    kind: .see,
                    imageURL: URL(string: "https://example.com/sculpture.jpg"),
                    sourceURL: URL(string: "https://example.com/sculpture"),
                    sourceName: "Wikipedia",
                    latitude: 49.2860,
                    longitude: -123.1180
                ),
                self.activity(
                    id: "palace-guide",
                    name: "Royal Palace",
                    summary: """
                    The ceremonial palace remains one of the city's signature heritage sites, with daily guard rituals, restored state rooms, and broad public squares that make it a reliable first stop for visitors.
                    """,
                    category: "Heritage",
                    kind: .see,
                    sourceURL: URL(string: "https://en.wikivoyage.org/wiki/Test#Royal_Palace"),
                    sourceName: "Wikivoyage"
                ),
                self.activity(
                    id: "palace-osm",
                    name: "Royal Palace",
                    summary: "Historic palace complex.",
                    category: "Landmark",
                    kind: .see,
                    imageURL: URL(string: "https://example.com/palace.jpg"),
                    officialURL: URL(string: "https://palace.example.com"),
                    sourceURL: URL(string: "https://en.wikipedia.org/wiki/Royal_Palace"),
                    sourceName: "OpenStreetMap",
                    hours: "Daily 10:00-18:00",
                    address: "1 Palace Square",
                    latitude: 49.2827,
                    longitude: -123.1207,
                    wikidataIdentifier: "Q123"
                )
            ],
            for: self.city,
            demandSignals: demandSignals,
            limit: 2
        )

        let firstActivity = try #require(rankedActivities.first)
        #expect(firstActivity.name == "Royal Palace")
        #expect(firstActivity.officialURL != nil)
        #expect(firstActivity.address == "1 Palace Square")
        #expect(firstActivity.sourceName == "Wikivoyage")
    }

    @Test func topActivitiesUsesPageviewDemandWhenReviewQueriesAreUnavailable() throws {
        let demandSignals = [
            CityActivityRanking.activityKey(for: "Historic Fortress"): CityActivityRanking.ActivityDemandSignal(
                popularityRank: nil,
                crossQueryAppearanceCount: 0,
                reviewQueryAppearanceCount: 0,
                pageviewCount: 610_000,
                pageviewRank: 1
            ),
            CityActivityRanking.activityKey(for: "Riverside Gallery"): CityActivityRanking.ActivityDemandSignal(
                popularityRank: nil,
                crossQueryAppearanceCount: 0,
                reviewQueryAppearanceCount: 0,
                pageviewCount: 90_000,
                pageviewRank: 2
            )
        ]

        let rankedActivities = CityActivityRanking.topActivities(
            from: [
                self.activity(
                    id: "gallery",
                    name: "Riverside Gallery",
                    summary: "A well-documented gallery with a website, practical details, and strong imagery.",
                    category: "Gallery",
                    kind: .see,
                    imageURL: URL(string: "https://example.com/gallery.jpg"),
                    officialURL: URL(string: "https://example.com/gallery"),
                    sourceURL: URL(string: "https://example.com/gallery-source"),
                    sourceName: "Wikivoyage",
                    hours: "Daily",
                    address: "2 River Road",
                    latitude: 49.2862,
                    longitude: -123.1176
                ),
                self.activity(
                    id: "fortress",
                    name: "Historic Fortress",
                    summary: "A major heritage landmark with deep city significance.",
                    category: "Heritage",
                    kind: .see,
                    sourceURL: URL(string: "https://example.com/fortress-source"),
                    sourceName: "Wikipedia",
                    latitude: 49.2820,
                    longitude: -123.1210
                )
            ],
            for: self.city,
            demandSignals: demandSignals,
            limit: 1
        )

        let firstActivity = try #require(rankedActivities.first)
        #expect(firstActivity.name == "Historic Fortress")
    }

    @Test func topActivitiesBalancesCategoryVarietyInFinalSelection() {
        let rankedActivities = CityActivityRanking.topActivities(
            from: [
                self.activity(
                    id: "tower",
                    name: "North Tower",
                    summary: "A landmark observation tower with skyline views and a popular city-center plaza.",
                    category: "Landmark",
                    kind: .see,
                    imageURL: URL(string: "https://example.com/tower.jpg"),
                    sourceURL: URL(string: "https://example.com/tower"),
                    sourceName: "Wikivoyage",
                    latitude: 49.2827,
                    longitude: -123.1207
                ),
                self.activity(
                    id: "museum",
                    name: "Grand City Museum",
                    summary: "A major museum with broad collections and an acclaimed architecture wing.",
                    category: "Museum",
                    kind: .see,
                    imageURL: URL(string: "https://example.com/museum.jpg"),
                    sourceURL: URL(string: "https://example.com/museum"),
                    sourceName: "Wikipedia",
                    latitude: 49.2830,
                    longitude: -123.1198
                ),
                self.activity(
                    id: "harbor",
                    name: "Harbor Promenade",
                    summary: "A waterside walk with public art, bike lanes, and sunset viewpoints for an easy active outing.",
                    category: "Nature",
                    kind: .do,
                    officialURL: URL(string: "https://example.com/harbor"),
                    sourceURL: URL(string: "https://example.com/harbor-guide"),
                    sourceName: "Wikivoyage",
                    hours: "Open daily",
                    latitude: 49.2798,
                    longitude: -123.1215
                )
            ],
            for: self.city,
            limit: 2
        )

        #expect(rankedActivities.count == 2)
        #expect(Set(rankedActivities.map(\.category)).count == 2)
        #expect(rankedActivities.contains { $0.name == "Harbor Promenade" })
    }

    @Test func topActivitiesDeduplicatesNormalizedNameVariants() {
        let rankedActivities = CityActivityRanking.topActivities(
            from: [
                self.activity(
                    id: "old-town-guide",
                    name: "Old Town",
                    summary: "A preserved historic district filled with plazas, churches, and local markets.",
                    category: "Culture",
                    kind: .do,
                    sourceURL: URL(string: "https://example.com/old-town-guide"),
                    sourceName: "Wikivoyage"
                ),
                self.activity(
                    id: "old-town-map",
                    name: "Old-Town",
                    summary: "Historic central quarter.",
                    category: "Heritage",
                    kind: .see,
                    officialURL: URL(string: "https://example.com/old-town"),
                    sourceURL: URL(string: "https://example.com/old-town-map"),
                    sourceName: "OpenStreetMap",
                    address: "Old Town Square",
                    latitude: 49.2815,
                    longitude: -123.1186
                ),
                self.activity(
                    id: "garden",
                    name: "Botanical Garden",
                    summary: "A large public garden with thematic collections and seasonal blooms.",
                    category: "Nature",
                    kind: .do,
                    sourceURL: URL(string: "https://example.com/garden"),
                    sourceName: "Wikipedia",
                    latitude: 49.2890,
                    longitude: -123.1150
                )
            ],
            for: self.city,
            limit: 3
        )

        #expect(rankedActivities.count == 2)
        #expect(rankedActivities.contains { $0.name == "Old Town" })
        #expect(rankedActivities.contains { $0.officialURL != nil && $0.name == "Old Town" })
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

    private func activity(
        id: String,
        name: String,
        summary: String,
        category: String,
        kind: CityActivity.Kind,
        imageURL: URL? = nil,
        officialURL: URL? = nil,
        sourceURL: URL? = nil,
        sourceName: String,
        hours: String? = nil,
        price: String? = nil,
        address: String? = nil,
        directions: String? = nil,
        timingTip: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        wikidataIdentifier: String? = nil
    ) -> CityActivity {
        CityActivity(
            id: id,
            name: name,
            summary: summary,
            category: category,
            kind: kind,
            imageURL: imageURL,
            officialURL: officialURL,
            sourceURL: sourceURL,
            sourceName: sourceName,
            hours: hours,
            price: price,
            address: address,
            directions: directions,
            timingTip: timingTip,
            latitude: latitude,
            longitude: longitude,
            wikidataIdentifier: wikidataIdentifier,
            sourcePageTitle: nil,
            sourceAnchor: nil
        )
    }
}
