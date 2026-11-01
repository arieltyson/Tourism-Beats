import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

// MARK: - TripActivityMapsTests

@Suite(.serialized)
@MainActor
struct TripActivityMapsTests {
    @Test func searchURLJoinsTheNonEmptyParts() throws {
        let url = try #require(GoogleMapsLink.searchURL(for: ["Le Chic Shack", nil, "  ", "Quebec City"]))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "www.google.com")
        #expect(components.path == "/maps/search/")
        #expect(components.queryItems?.first { $0.name == "api" }?.value == "1")
        #expect(components.queryItems?.first { $0.name == "query" }?.value == "Le Chic Shack, Quebec City")
    }

    @Test func searchURLIsNilWithNothingToSearch() {
        #expect(GoogleMapsLink.searchURL(for: [nil, "", " "]) == nil)
    }

    @Test func aSightWithoutAnAddressIsFoundByNameInTheTripsCity() throws {
        let container = try Self.makeInMemoryContainer()
        let activity = Self.activity("Chateau Frontenac", type: .attraction, in: container)

        #expect(try Self.query(of: activity) == "Chateau Frontenac, Quebec City, Canada")
    }

    @Test func aRestaurantIsFoundByNameAndAddress() throws {
        let container = try Self.makeInMemoryContainer()
        let activity = Self.activity("Le Chic Shack", type: .food, location: "15 Rue du Fort", in: container)

        #expect(try Self.query(of: activity) == "Le Chic Shack, 15 Rue du Fort, Quebec City, Canada")
    }

    @Test func otherActivitiesNeedAnAddressOfTheirOwn() throws {
        let container = try Self.makeInMemoryContainer()
        let flight = Self.activity("Flight home", type: .flight, in: container)
        let train = Self.activity("Train to Montreal", type: .transport, location: "Gare du Palais", in: container)

        #expect(flight.mapsURL == nil)
        #expect(try Self.query(of: train) == "Gare du Palais, Quebec City, Canada")
    }

    // MARK: Helpers

    private static func activity(
        _ name: String,
        type: ActivityType,
        location: String? = nil,
        in container: ModelContainer
    ) -> TripActivity {
        let trip = Trip(name: "Le Test de Français", city: "Quebec City", country: "Canada")
        let day = TripDay(dayNumber: 1, trip: trip)
        let activity = TripActivity(name: name, type: type, location: location, day: day)
        container.mainContext.insert(trip)
        container.mainContext.insert(day)
        container.mainContext.insert(activity)
        return activity
    }

    private static func query(of activity: TripActivity) throws -> String? {
        let url = try #require(activity.mapsURL)
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "query" }?
            .value
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Trip.self,
            TripDay.self,
            TripActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
