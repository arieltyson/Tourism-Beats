import SwiftData
import Testing
@testable import Tourism_Beats

@Suite(.serialized)
@MainActor
struct TripSeedServiceTests {
    @Test func seedIfNeededCreatesThreeSampleTripsWithActivities() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        try #expect(trips.count == 3)
        try #expect(Set(trips.map(\.name)) == ["Trinidad and Tobago", "Vancouver, BC", "San Francisco"])
        try #expect(trips.allSatisfy(\.isSample))
        try #expect(trips.allSatisfy { $0.activityCount > 0 })
    }

    @Test func seedIfNeededIsIdempotent() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)
        try TripSeedService.seedIfNeeded(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        try #expect(trips.count == 3)
    }

    @Test func registerUserCreatedTripRemovesSamples() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let customTrip = Trip(
            name: "Tokyo Spring",
            city: "Tokyo",
            country: "Japan"
        )
        modelContext.insert(customTrip)
        try modelContext.save()

        try TripSeedService.registerUserCreatedTrip(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())
        try #expect(trips.count == 1)
        try #expect(trips.first?.name == "Tokyo Spring")
    }

    @Test func deleteTripRestoresSamplesWhenDeletingLastUserTrip() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let customTrip = Trip(
            name: "Tokyo Spring",
            city: "Tokyo",
            country: "Japan"
        )
        modelContext.insert(customTrip)
        try modelContext.save()

        try TripSeedService.registerUserCreatedTrip(in: modelContext)
        try TripSeedService.deleteTrip(customTrip, in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())
        try #expect(trips.count == 3)
        try #expect(trips.allSatisfy(\.isSample))
    }

    @Test func deleteTripDoesNotRestoreSamplesWhenDeletingSampleTrip() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())
        let sampleTrip = try #require(trips.first)

        try TripSeedService.deleteTrip(sampleTrip, in: modelContext)

        let remainingTrips = try modelContext.fetch(FetchDescriptor<Trip>())
        try #expect(remainingTrips.count == 2)
        try #expect(remainingTrips.allSatisfy(\.isSample))
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Trip.self,
            TripDay.self,
            TripActivity.self,
            configurations: configuration
        )
    }
}
