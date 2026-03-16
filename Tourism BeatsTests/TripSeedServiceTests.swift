import SwiftData
import Testing
@testable import Tourism_Beats

@Suite(.serialized)
@MainActor
struct TripSeedServiceTests {
    @Test func seedIfNeededCreatesThreeSampleTripsWithActivities() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let userDefaults = self.makeUserDefaults()

        try TripSeedService.seedIfNeeded(
            in: modelContext,
            userDefaults: userDefaults
        )

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        #expect(trips.count == 3)
        #expect(Set(trips.map(\.name)) == ["Trinidad and Tobago", "Vancouver, BC", "San Francisco"])
        #expect(trips.allSatisfy(\.isSample))
        #expect(trips.allSatisfy { $0.activityCount > 0 })
    }

    @Test func seedIfNeededIsIdempotent() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let userDefaults = self.makeUserDefaults()

        try TripSeedService.seedIfNeeded(
            in: modelContext,
            userDefaults: userDefaults
        )
        try TripSeedService.seedIfNeeded(
            in: modelContext,
            userDefaults: userDefaults
        )

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        #expect(trips.count == 3)
    }

    @Test func registerUserCreatedTripRemovesSamplesAndBlocksFutureAutoSeeding()
        throws
    {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let userDefaults = self.makeUserDefaults()

        try TripSeedService.seedIfNeeded(
            in: modelContext,
            userDefaults: userDefaults
        )

        let customTrip = Trip(
            name: "Tokyo Spring",
            city: "Tokyo",
            country: "Japan"
        )
        modelContext.insert(customTrip)
        try modelContext.save()

        try TripSeedService.registerUserCreatedTrip(
            in: modelContext,
            userDefaults: userDefaults
        )

        var trips = try modelContext.fetch(FetchDescriptor<Trip>())
        #expect(trips.count == 1)
        #expect(trips.first?.name == "Tokyo Spring")
        #expect(TripSeedService.hasCreatedCustomTrip(userDefaults: userDefaults))

        modelContext.delete(customTrip)
        try modelContext.save()

        try TripSeedService.seedIfNeeded(
            in: modelContext,
            userDefaults: userDefaults
        )

        trips = try modelContext.fetch(FetchDescriptor<Trip>())
        #expect(trips.isEmpty)
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

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "TripSeedServiceTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
