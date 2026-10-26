import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

@Suite(.serialized)
@MainActor
struct TripScheduleAlignmentTests {
    @Test func addingDayExtendsDatedTripEndDate() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = self.makeDatedTrip(dayCount: 3, in: modelContext)

        modelContext.insert(
            TripDay(
                dayNumber: trip.nextDayNumber,
                date: trip.nextDayDate,
                trip: trip
            )
        )
        trip.alignScheduleWithDays()
        try modelContext.save()

        #expect(trip.dayCount == 4)
        #expect(trip.endDate == Self.date(2_026, 12, 23))
        #expect(trip.sortedDays.map(\.dayNumber) == [1, 2, 3, 4])
        #expect(trip.isScheduleAligned())
    }

    @Test func removingMiddleDayRenumbersAndRedatesRemainingDays() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = self.makeDatedTrip(dayCount: 4, in: modelContext)
        let removedDay = try #require(trip.sortedDays.dropFirst().first)

        trip.days?.removeAll { $0 == removedDay }
        modelContext.delete(removedDay)
        trip.alignScheduleWithDays()
        try modelContext.save()

        #expect(trip.sortedDays.map(\.dayNumber) == [1, 2, 3])
        #expect(trip.sortedDays.map(\.date) == [
            Self.date(2_026, 12, 20),
            Self.date(2_026, 12, 21),
            Self.date(2_026, 12, 22)
        ])
        #expect(trip.endDate == Self.date(2_026, 12, 22))
        #expect(trip.isScheduleAligned())
    }

    @Test func rangeLongerThanItineraryIsReportedAsMisaligned() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = self.makeDatedTrip(dayCount: 3, in: modelContext)

        trip.endDate = Self.date(2_026, 12, 27)

        #expect(!trip.isScheduleAligned())

        trip.alignScheduleWithDays()

        #expect(trip.endDate == Self.date(2_026, 12, 22))
        #expect(trip.isScheduleAligned())
    }

    @Test func undatedTripOnlyRenumbersDays() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = Trip(name: "Someday", city: "Lisbon", country: "Portugal")
        modelContext.insert(trip)
        modelContext.insert(TripDay(dayNumber: 2, trip: trip))
        modelContext.insert(TripDay(dayNumber: 5, trip: trip))

        trip.alignScheduleWithDays()

        #expect(trip.sortedDays.map(\.dayNumber) == [1, 2])
        #expect(trip.sortedDays.allSatisfy { $0.date == nil })
        #expect(trip.startDate == nil)
        #expect(trip.endDate == nil)
        #expect(trip.isScheduleAligned())
    }

    private func makeDatedTrip(dayCount: Int, in modelContext: ModelContext) -> Trip {
        let trip = Trip(
            name: "Trinidad and Tobago",
            city: "Port of Spain",
            country: "Trinidad and Tobago",
            startDate: Self.date(2_026, 12, 20)
        )
        modelContext.insert(trip)

        for index in 0 ..< dayCount {
            modelContext.insert(
                TripDay(
                    dayNumber: index + 1,
                    date: Self.date(2_026, 12, 20 + index),
                    trip: trip
                )
            )
        }

        trip.alignScheduleWithDays()
        return trip
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

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(
            from: DateComponents(year: year, month: month, day: day)
        )
    }
}
