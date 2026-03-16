import Foundation
import SwiftData

// MARK: - TripSeedService

/// Seeds sample trips on first launch so the Trips tab isn't empty.
///
/// Checks whether any `Trip` records exist. If the store is empty,
/// inserts three skeleton itineraries demonstrating the feature.
enum TripSeedService {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Trip>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        Self.seedTrinidad(in: context)
        Self.seedVancouver(in: context)
        Self.seedSanFrancisco(in: context)
    }

    // MARK: - Trinidad & Tobago

    private static func seedTrinidad(in context: ModelContext) {
        let trip = Trip(
            name: "Christmas in Trinidad",
            city: "Port of Spain",
            country: "Trinidad and Tobago",
            startDate: Self.date(2_026, 12, 20),
            endDate: Self.date(2_026, 12, 27),
            status: .upcoming
        )
        context.insert(trip)

        let day1 = TripDay(dayNumber: 1, date: Self.date(2_026, 12, 20), label: "Arrival Day", trip: trip)
        context.insert(day1)
        Self.addActivity("Arrive at Piarco Airport", type: .flight, time: Self.time(14, 30), day: day1, in: context)
        Self.addActivity("Check into hotel", type: .accommodation, day: day1, in: context)
        Self.addActivity("Dinner on Ariapita Avenue", type: .food, time: Self.time(19, 0), day: day1, in: context)

        let day2 = TripDay(dayNumber: 2, date: Self.date(2_026, 12, 21), label: "Beach Day", trip: trip)
        context.insert(day2)
        Self.addActivity("Wake up", type: .wakeUp, time: Self.time(7, 0), day: day2, in: context)
        Self.addActivity(
            "Doubles for breakfast",
            type: .food,
            time: Self.time(8, 0),
            notes: "Try Sauce Doubles on the highway",
            day: day2,
            in: context
        )
        Self.addActivity("Maracas Bay Beach", type: .attraction, time: Self.time(10, 0), day: day2, in: context)
        Self.addActivity("Bake and Shark at Richard's", type: .food, time: Self.time(12, 30), day: day2, in: context)

        let day3 = TripDay(dayNumber: 3, date: Self.date(2_026, 12, 22), label: "Port of Spain Exploration", trip: trip)
        context.insert(day3)
        Self.addActivity("Queen's Park Savannah walk", type: .attraction, time: Self.time(9, 0), day: day3, in: context)
        Self.addActivity("Lunch at Veni Mangé", type: .food, time: Self.time(12, 0), day: day3, in: context)
        Self.addActivity("Fort George lookout", type: .attraction, time: Self.time(15, 0), day: day3, in: context)
    }

    // MARK: - Vancouver

    private static func seedVancouver(in context: ModelContext) {
        let trip = Trip(
            name: "Vancouver Winter Getaway",
            city: "Vancouver",
            country: "Canada",
            startDate: Self.date(2_027, 2, 14),
            endDate: Self.date(2_027, 2, 20),
            status: .upcoming
        )
        context.insert(trip)

        let day1 = TripDay(dayNumber: 1, date: Self.date(2_027, 2, 14), label: "Arrival + Gastown", trip: trip)
        context.insert(day1)
        Self.addActivity("Arrive at YVR", type: .flight, time: Self.time(11, 0), day: day1, in: context)
        Self.addActivity("Check into hotel", type: .accommodation, time: Self.time(14, 0), day: day1, in: context)
        Self.addActivity("Walk around Gastown", type: .attraction, time: Self.time(16, 0), day: day1, in: context)
        Self.addActivity("Dinner at Ramen Danbo", type: .food, time: Self.time(18, 30), day: day1, in: context)

        let day2 = TripDay(dayNumber: 2, date: Self.date(2_027, 2, 15), label: "Grouse Mountain", trip: trip)
        context.insert(day2)
        Self.addActivity("Wake up", type: .wakeUp, time: Self.time(7, 30), day: day2, in: context)
        Self.addActivity("Brunch at Jam Cafe", type: .food, time: Self.time(9, 0), day: day2, in: context)
        Self.addActivity("Grouse Mountain skiing", type: .attraction, time: Self.time(12, 0), day: day2, in: context)

        let day3 = TripDay(dayNumber: 3, date: Self.date(2_027, 2, 16), label: "Granville Island", trip: trip)
        context.insert(day3)
        Self.addActivity(
            "Granville Island Public Market",
            type: .shopping,
            time: Self.time(10, 0),
            day: day3,
            in: context
        )
        Self.addActivity("Lunch at The Sandbar", type: .food, time: Self.time(13, 0), day: day3, in: context)
        Self.addActivity("Stanley Park Seawall walk", type: .attraction, time: Self.time(15, 0), day: day3, in: context)
    }

    // MARK: - San Francisco

    private static func seedSanFrancisco(in context: ModelContext) {
        let trip = Trip(
            name: "San Francisco Summer",
            city: "San Francisco",
            country: "United States",
            startDate: Self.date(2_027, 7, 5),
            endDate: Self.date(2_027, 7, 10),
            status: .upcoming
        )
        context.insert(trip)

        let day1 = TripDay(dayNumber: 1, date: Self.date(2_027, 7, 5), label: "Golden Gate + Wharf", trip: trip)
        context.insert(day1)
        Self.addActivity("Golden Gate Bridge walk", type: .attraction, time: Self.time(9, 0), day: day1, in: context)
        Self.addActivity("Lunch at Fisherman's Wharf", type: .food, time: Self.time(12, 30), day: day1, in: context)
        Self.addActivity("Ghirardelli Square", type: .shopping, time: Self.time(14, 30), day: day1, in: context)

        let day2 = TripDay(dayNumber: 2, date: Self.date(2_027, 7, 6), label: "Alcatraz + Chinatown", trip: trip)
        context.insert(day2)
        Self.addActivity(
            "Alcatraz Island tour",
            type: .attraction,
            time: Self.time(9, 30),
            notes: "Book ferry tickets early",
            day: day2,
            in: context
        )
        Self.addActivity("Lunch in Chinatown", type: .food, time: Self.time(13, 0), day: day2, in: context)
        Self.addActivity("Cable car ride", type: .transport, time: Self.time(15, 0), day: day2, in: context)

        let day3 = TripDay(dayNumber: 3, date: Self.date(2_027, 7, 7), label: "Mission District", trip: trip)
        context.insert(day3)
        Self.addActivity("Brunch at Tartine Bakery", type: .food, time: Self.time(10, 0), day: day3, in: context)
        Self.addActivity(
            "Mission murals walking tour",
            type: .attraction,
            time: Self.time(12, 0),
            day: day3,
            in: context
        )
        Self.addActivity(
            "Dinner at La Taqueria",
            type: .food,
            time: Self.time(18, 0),
            notes: "Famous Mission burrito",
            day: day3,
            in: context
        )
    }

    // MARK: - Helpers

    private static func addActivity(
        _ name: String,
        type: ActivityType,
        time: Date? = nil,
        notes: String? = nil,
        day: TripDay,
        in context: ModelContext
    ) {
        let activity = TripActivity(
            name: name,
            time: time,
            type: type,
            notes: notes,
            day: day
        )
        context.insert(activity)
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .now
    }

    private static func time(_ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? .now
    }
}
