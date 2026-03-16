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

        #expect(trips.count == 3)
        #expect(Set(trips.map(\.name)) == ["Trinidad and Tobago", "Vancouver, BC", "San Francisco"])
        #expect(trips.allSatisfy(\.isSample))
        #expect(trips.allSatisfy { $0.activityCount > 0 })
    }

    @Test func seedIfNeededIsIdempotent() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)
        try TripSeedService.seedIfNeeded(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        #expect(trips.count == 3)
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
