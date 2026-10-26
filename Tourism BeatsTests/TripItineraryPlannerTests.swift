import Testing
@testable import Tourism_Beats

struct TripItineraryPlannerTests {
    private typealias Planner = TripItineraryPlanner
    private typealias Fixtures = TripPlanningFixtures

    @Test func emptyDaysGetTwoSightsAndTwoMealsEach() {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 3),
            activities: Fixtures.activities(count: 18),
            restaurants: Fixtures.restaurants(count: 18),
            excludedPlaceNames: []
        )

        #expect(plan.count == 3)
        for daySuggestions in plan {
            #expect(daySuggestions.map(\.slot) == [.morning, .lunch, .afternoon, .dinner])
            #expect(daySuggestions.map(\.type) == [.attraction, .food, .attraction, .food])
        }
    }

    @Test func noPlaceIsSuggestedTwiceAcrossTheTrip() {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 8),
            activities: Fixtures.activities(count: 18),
            restaurants: Fixtures.restaurants(count: 18),
            excludedPlaceNames: []
        )

        let names = plan.flatMap { $0.map(\.name) }
        #expect(names.count == Set(names).count)
        #expect(Set(plan.flatMap { $0.map(\.id) }).count == names.count)
    }

    @Test func shortPoolGivesEveryDayASightBeforeAnyDayGetsTwo() {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 4),
            activities: Fixtures.activities(count: 5),
            restaurants: [],
            excludedPlaceNames: []
        )

        #expect(plan.map(\.count) == [2, 1, 1, 1])
        #expect(plan.map { $0.first?.name } == ["Sight 1", "Sight 2", "Sight 3", "Sight 4"])
    }

    @Test func placesAlreadyInTripAreNotSuggestedAgain() {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 1),
            activities: [
                Fixtures.activity("Fort George"),
                Fixtures.activity("Queen's Park Savannah"),
                Fixtures.activity("Royal Botanic Gardens")
            ],
            restaurants: [Fixtures.restaurant("Veni Mangé"), Fixtures.restaurant("Chaud Café")],
            excludedPlaceNames: ["fort george", "Veni Mange"]
        )

        let names = plan.flatMap { $0.map(\.name) }
        #expect(!names.contains("Fort George"))
        #expect(!names.contains("Veni Mangé"))
        #expect(names.contains("Queen's Park Savannah"))
        #expect(names.contains("Chaud Café"))
    }

    @Test func timedPlansCoverTheirSlotsButBreakfastKeepsMorningOpen() {
        let breakfastOnly = Planner.Day(
            existingActivities: [
                .init(type: .wakeUp, minuteOfDay: 7 * 60),
                .init(type: .food, minuteOfDay: 8 * 60)
            ],
            isFirstDayOfTrip: false,
            isLastDayOfTrip: false
        )
        let beachAndLunch = Planner.Day(
            existingActivities: [
                .init(type: .food, minuteOfDay: 8 * 60),
                .init(type: .attraction, minuteOfDay: 10 * 60),
                .init(type: .food, minuteOfDay: 12 * 60 + 30)
            ],
            isFirstDayOfTrip: false,
            isLastDayOfTrip: false
        )

        #expect(Planner.openSlots(for: breakfastOnly) == [.morning, .lunch, .afternoon, .dinner])
        #expect(Planner.openSlots(for: beachAndLunch) == [.afternoon, .dinner])
    }

    @Test func untimedPlansTakeTheEarliestMatchingSlot() {
        let day = Planner.Day(
            existingActivities: [
                .init(type: .attraction, minuteOfDay: nil),
                .init(type: .food, minuteOfDay: nil),
                .init(type: .accommodation, minuteOfDay: nil)
            ],
            isFirstDayOfTrip: false,
            isLastDayOfTrip: false
        )

        #expect(Planner.openSlots(for: day) == [.afternoon, .dinner])
    }

    @Test func arrivalFlightKeepsSlotsBeforeLandingFree() {
        let arrivalDay = Planner.Day(
            existingActivities: [.init(type: .flight, minuteOfDay: 14 * 60 + 30)],
            isFirstDayOfTrip: true,
            isLastDayOfTrip: false
        )

        #expect(Planner.openSlots(for: arrivalDay) == [.dinner])
    }

    @Test func departureFlightKeepsSlotsAfterTakeOffFree() {
        let departureDay = Planner.Day(
            existingActivities: [.init(type: .flight, minuteOfDay: 16 * 60)],
            isFirstDayOfTrip: false,
            isLastDayOfTrip: true
        )

        #expect(Planner.openSlots(for: departureDay) == [.morning, .lunch])
    }

    @Test func untimedArrivalFlightLeavesOnlyDinner() {
        let arrivalDay = Planner.Day(
            existingActivities: [.init(type: .flight, minuteOfDay: nil)],
            isFirstDayOfTrip: true,
            isLastDayOfTrip: false
        )

        #expect(Planner.openSlots(for: arrivalDay) == [.dinner])
    }

    @Test func fullyPlannedDayGetsNoSuggestions() {
        let fullDay = Planner.Day(
            existingActivities: [
                .init(type: .attraction, minuteOfDay: 9 * 60),
                .init(type: .food, minuteOfDay: 13 * 60),
                .init(type: .shopping, minuteOfDay: 16 * 60),
                .init(type: .food, minuteOfDay: 20 * 60)
            ],
            isFirstDayOfTrip: false,
            isLastDayOfTrip: false
        )

        let plan = Planner.plan(
            days: [fullDay],
            activities: Fixtures.activities(count: 6),
            restaurants: Fixtures.restaurants(count: 6),
            excludedPlaceNames: []
        )

        #expect(plan == [[]])
    }

    @Test func secondSightAndMealsStayNearTheFirstSight() {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 1),
            activities: [
                Fixtures.activity("Downtown Museum", latitude: 10.650, longitude: -61.510),
                Fixtures.activity("Far Waterfall", latitude: 10.800, longitude: -61.200),
                Fixtures.activity("Downtown Cathedral", latitude: 10.652, longitude: -61.512)
            ],
            restaurants: [
                Fixtures.restaurant("Far Grill", latitude: 10.790, longitude: -61.210),
                Fixtures.restaurant("Downtown Roti", latitude: 10.651, longitude: -61.511),
                Fixtures.restaurant("Harbour Bistro", latitude: 10.655, longitude: -61.515)
            ],
            excludedPlaceNames: []
        )

        let names = plan.first?.map(\.name)
        #expect(names == ["Downtown Museum", "Downtown Roti", "Downtown Cathedral", "Harbour Bistro"])
    }

    @Test func suggestionsCarryLocationAndContextNotes() throws {
        let plan = Planner.plan(
            days: Self.emptyDays(count: 1),
            activities: [Fixtures.activity("Fort George", category: "Viewpoint", timingTip: "Go at sunset")],
            restaurants: [Fixtures.restaurant("Chaud Café", cuisine: "Creole")],
            excludedPlaceNames: []
        )

        let suggestions = try #require(plan.first)
        let sight = try #require(suggestions.first { $0.type == .attraction })
        let meal = try #require(suggestions.first { $0.type == .food })

        #expect(sight.location == "Fort George Road")
        #expect(sight.notes == "Viewpoint · Go at sunset")
        #expect(meal.location == "Chaud Café Street")
        #expect(meal.notes == "Creole")
    }

    private static func emptyDays(count: Int) -> [Planner.Day] {
        (0 ..< count).map { index in
            Planner.Day(
                existingActivities: [],
                isFirstDayOfTrip: index == 0,
                isLastDayOfTrip: index == count - 1
            )
        }
    }
}
