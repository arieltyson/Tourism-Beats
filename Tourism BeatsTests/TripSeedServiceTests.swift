import Foundation
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

    @Test func sampleDateRangesMatchSeededDays() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())

        for trip in trips {
            #expect(trip.isScheduleAligned(), "\(trip.name) advertises days it does not have")
            #expect(trip.endDate == trip.sortedDays.last?.date)
        }
    }

    @Test func seedIfNeededRepairsStaleSampleRangeAndKeepsUserAddedDays() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        try TripSeedService.seedIfNeeded(in: modelContext)

        let trinidad = try #require(
            try modelContext.fetch(FetchDescriptor<Trip>()).first { $0.name == "Trinidad and Tobago" }
        )
        let lastSeededDate = try #require(trinidad.sortedDays.last?.date)
        let staleEndDate = try #require(
            Calendar.current.date(byAdding: .day, value: 5, to: lastSeededDate)
        )
        modelContext.insert(TripDay(dayNumber: trinidad.nextDayNumber, trip: trinidad))
        trinidad.endDate = staleEndDate
        try modelContext.save()

        try TripSeedService.seedIfNeeded(in: modelContext)

        let expectedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: lastSeededDate)
        #expect(trinidad.dayCount == 4)
        #expect(trinidad.endDate == expectedEndDate)
        #expect(trinidad.sortedDays.last?.date == expectedEndDate)
        #expect(trinidad.isScheduleAligned())
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
