import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

// MARK: - TripSuggestionsViewModelTests

@Suite(.serialized)
@MainActor
struct TripSuggestionsViewModelTests {
    private typealias Fixtures = TripPlanningFixtures

    @Test func tripScopeSuggestsForEveryOpenDayAndSelectsAllByDefault() async throws {
        let container = try Self.makeInMemoryContainer()
        let trip = Self.makeTrip(dayCount: 3, in: container.mainContext)
        let viewModel = Self.makeViewModel(trip: trip, scope: .trip)

        await viewModel.load()

        let days = try Self.loadedDays(viewModel)
        #expect(days.count == 3)
        #expect(days.allSatisfy { $0.suggestions.count == 4 })
        #expect(viewModel.selectedCount == 12)
        #expect(viewModel.addButtonTitle == "Add 12")
        #expect(viewModel.addButtonAccessibilityLabel == "Add 12 activities")
        #expect(viewModel.coverageNote == nil)
    }

    @Test func dayScopeOnlyPlansThatDayAndSkipsPlacesElsewhereInTrip() async throws {
        let container = try Self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = Self.makeTrip(dayCount: 2, in: modelContext)
        let firstDay = try #require(trip.sortedDays.first)
        let secondDay = try #require(trip.sortedDays.last)
        modelContext.insert(TripActivity(name: "Sight 1", type: .attraction, day: firstDay))
        let viewModel = Self.makeViewModel(trip: trip, scope: .day(secondDay))

        await viewModel.load()

        let days = try Self.loadedDays(viewModel)
        #expect(days.map(\.day) == [secondDay])
        #expect(!days.flatMap { $0.suggestions.map(\.name) }.contains("Sight 1"))
    }

    @Test func applySelectionAddsOnlySelectedSuggestionsAtSlotTimes() async throws {
        let container = try Self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = Self.makeTrip(dayCount: 1, in: modelContext)
        let day = try #require(trip.sortedDays.first)
        let viewModel = Self.makeViewModel(trip: trip, scope: .day(day))

        await viewModel.load()
        let suggestions = try #require(Self.loadedDays(viewModel).first?.suggestions)
        let skipped = try #require(suggestions.first { $0.slot == .dinner })
        viewModel.toggle(skipped)

        let addedCount = try viewModel.applySelection(in: modelContext)

        #expect(addedCount == 3)
        #expect(day.activityCount == 3)
        #expect(!day.sortedActivities.map(\.name).contains(skipped.name))

        let morning = try #require(day.sortedActivities.first)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: morning.time ?? .distantPast
        )
        #expect(components == DateComponents(year: 2_026, month: 12, day: 20, hour: 9, minute: 30))
        #expect(morning.type == .attraction)
        #expect(morning.activityStatus == .planned)
    }

    @Test func fullyPlannedDayReportsAlreadyPlannedWithoutFetching() async throws {
        let container = try Self.makeInMemoryContainer()
        let modelContext = container.mainContext
        let trip = Self.makeTrip(dayCount: 1, in: modelContext)
        let day = try #require(trip.sortedDays.first)
        let plans: [(hour: Int, type: ActivityType)] = [(9, .attraction), (13, .food), (16, .shopping), (20, .food)]
        for plan in plans {
            modelContext.insert(
                TripActivity(
                    name: "Plan \(plan.hour)",
                    time: Calendar.current.date(bySettingHour: plan.hour, minute: 0, second: 0, of: .now),
                    type: plan.type,
                    day: day
                )
            )
        }
        let activityService = MockActivityService(activities: Fixtures.activities(count: 6))
        let viewModel = TripSuggestionsViewModel(
            trip: trip,
            city: Fixtures.portOfSpain,
            scope: .day(day),
            activityService: activityService,
            restaurantService: MockRestaurantService(restaurants: Fixtures.restaurants(count: 6))
        )

        await viewModel.load()

        guard case let .unavailable(title, _, canRetry) = viewModel.state else {
            Issue.record("Expected an unavailable state")
            return
        }
        #expect(title == "Already Planned")
        #expect(!canRetry)
        #expect(await activityService.requestCount() == 0)
    }

    @Test func emptyGuidesOfferRetry() async throws {
        let container = try Self.makeInMemoryContainer()
        let trip = Self.makeTrip(dayCount: 2, in: container.mainContext)
        let viewModel = TripSuggestionsViewModel(
            trip: trip,
            city: Fixtures.portOfSpain,
            scope: .trip,
            activityService: MockActivityService(activities: []),
            restaurantService: MockRestaurantService(restaurants: [])
        )

        await viewModel.load()

        guard case let .unavailable(title, _, canRetry) = viewModel.state else {
            Issue.record("Expected an unavailable state")
            return
        }
        #expect(title == "Guide Unavailable")
        #expect(canRetry)
    }

    @Test func shortGuideExplainsPartialCoverage() async throws {
        let container = try Self.makeInMemoryContainer()
        let trip = Self.makeTrip(dayCount: 8, in: container.mainContext)
        let viewModel = TripSuggestionsViewModel(
            trip: trip,
            city: Fixtures.portOfSpain,
            scope: .trip,
            activityService: MockActivityService(activities: Fixtures.activities(count: 5)),
            restaurantService: MockRestaurantService(restaurants: [])
        )

        await viewModel.load()

        #expect(try Self.loadedDays(viewModel).count == 5)
        #expect(viewModel.coverageNote?.contains("5 of 8 open days") == true)
    }

    // MARK: Helpers

    private static func makeViewModel(
        trip: Trip,
        scope: TripSuggestionsViewModel.Scope
    ) -> TripSuggestionsViewModel {
        TripSuggestionsViewModel(
            trip: trip,
            city: Fixtures.portOfSpain,
            scope: scope,
            activityService: MockActivityService(activities: Fixtures.activities(count: 18)),
            restaurantService: MockRestaurantService(restaurants: Fixtures.restaurants(count: 18))
        )
    }

    private static func loadedDays(
        _ viewModel: TripSuggestionsViewModel
    ) throws -> [TripSuggestionsViewModel.DaySuggestions] {
        guard case let .loaded(days) = viewModel.state else {
            throw LoadError.notLoaded
        }
        return days
    }

    private static func makeTrip(dayCount: Int, in modelContext: ModelContext) -> Trip {
        let startDate = Calendar.current.date(from: DateComponents(year: 2_026, month: 12, day: 20))
        let trip = Trip(
            name: "Trinidad and Tobago",
            city: "Port of Spain",
            country: "Trinidad and Tobago",
            startDate: startDate
        )
        modelContext.insert(trip)

        for index in 0 ..< dayCount {
            modelContext.insert(TripDay(dayNumber: index + 1, trip: trip))
        }

        trip.alignScheduleWithDays()
        return trip
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Trip.self,
            TripDay.self,
            TripActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private enum LoadError: Error {
        case notLoaded
    }
}

// MARK: - Mocks

extension TripSuggestionsViewModelTests {
    private actor MockActivityService: CityActivityProviding {
        private let activitiesToReturn: [CityActivity]
        private var totalRequests = 0

        init(activities: [CityActivity]) {
            self.activitiesToReturn = activities
        }

        func activities(for city: CityModel) async -> [CityActivity] {
            _ = city
            self.totalRequests += 1
            return self.activitiesToReturn
        }

        func requestCount() -> Int {
            self.totalRequests
        }
    }

    private actor MockRestaurantService: CityRestaurantProviding {
        private let restaurantsToReturn: [CityRestaurant]

        init(restaurants: [CityRestaurant]) {
            self.restaurantsToReturn = restaurants
        }

        func restaurants(for city: CityModel) async -> [CityRestaurant] {
            _ = city
            return self.restaurantsToReturn
        }
    }
}
