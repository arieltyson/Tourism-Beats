import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

// MARK: - TripStayRecommendationsViewModelTests

@MainActor
struct TripStayRecommendationsViewModelTests {
    /// Answers each query with the hotels listed for it, recording each one.
    private final class StubSearch: TripStaySearching, @unchecked Sendable {
        let staysByQuery: [String: [TripStay]]
        private(set) var queries: [String] = []

        init(staysByQuery: [String: [TripStay]]) {
            self.staysByQuery = staysByQuery
        }

        func stays(matching query: String, in area: TripStaySearchArea) async throws -> [TripStay] {
            self.queries.append(query)
            return self.staysByQuery[query] ?? []
        }
    }

    private static func stay(_ name: String) -> TripStay {
        TripStay(name: name, address: nil, latitude: 10.66, longitude: -61.51)
    }

    private static func trip(budget: TripBudget?) -> Trip {
        let trip = Trip(name: "Carnival", city: "Port of Spain", country: "Trinidad and Tobago")
        trip.budget = budget
        return trip
    }

    private static let estimator = TravelCostEstimator(
        reference: TravelCostReference(costLevels: ["TT": .high], dollarRates: [:])
    )

    @Test func aBudgetSearchesForTheHotelsItAffordsAndRecommendsAFew() async {
        // A one-day trip books one night, so this is the nightly amount.
        let budget = TripBudget(amounts: [.stay: 300, .food: 100, .fun: 50, .gettingAround: 50], currencyCode: "USD")
        let search = StubSearch(staysByQuery: [
            HotelClass.boutique.searchQuery: (1 ... 5).map { Self.stay("Boutique \($0)") }
        ])
        let viewModel = TripStayRecommendationsViewModel(
            trip: Self.trip(budget: budget),
            city: TripPlanningFixtures.portOfSpain,
            service: search,
            estimator: Self.estimator
        )

        await viewModel.load()

        #expect(viewModel.hotelClass == .boutique)
        #expect(abs((viewModel.nightlyBudget ?? 0) - 300) < 0.001)
        #expect(viewModel.state == .loaded((1 ... 3).map { Self.stay("Boutique \($0)") }))
    }

    @Test func aCityWithoutThatKindOfHotelFallsBackToAnyHotel() async {
        let budget = TripBudget(amounts: [.stay: 600, .food: 0, .fun: 0, .gettingAround: 0], currencyCode: "USD")
        let search = StubSearch(staysByQuery: ["": [Self.stay("Hilton")]])
        let viewModel = TripStayRecommendationsViewModel(
            trip: Self.trip(budget: budget),
            city: TripPlanningFixtures.portOfSpain,
            service: search,
            estimator: Self.estimator
        )

        await viewModel.load()

        #expect(search.queries == [HotelClass.luxury.searchQuery, ""])
        #expect(viewModel.state == .loaded([Self.stay("Hilton")]))
    }

    @Test func withoutABudgetItRecommendsAnyHotel() async {
        let search = StubSearch(staysByQuery: ["": [Self.stay("Hyatt")]])
        let viewModel = TripStayRecommendationsViewModel(
            trip: Self.trip(budget: nil),
            city: TripPlanningFixtures.portOfSpain,
            service: search,
            estimator: Self.estimator
        )

        await viewModel.load()

        #expect(viewModel.hotelClass == nil)
        #expect(search.queries == [""])
        #expect(viewModel.state == .loaded([Self.stay("Hyatt")]))
    }

    @Test func noHotelsLeavesTheSectionOut() async {
        let viewModel = TripStayRecommendationsViewModel(
            trip: Self.trip(budget: nil),
            city: TripPlanningFixtures.portOfSpain,
            service: StubSearch(staysByQuery: [:]),
            estimator: Self.estimator
        )

        await viewModel.load()

        #expect(viewModel.state == .unavailable)
    }

    @Test func pickingAHotelAgainPutsItBack() async {
        let hyatt = Self.stay("Hyatt")
        let viewModel = TripStayRecommendationsViewModel(
            trip: Self.trip(budget: nil),
            city: TripPlanningFixtures.portOfSpain,
            service: StubSearch(staysByQuery: ["": [hyatt, Self.stay("Hilton")]]),
            estimator: Self.estimator
        )
        await viewModel.load()

        viewModel.toggle(hyatt)
        #expect(viewModel.selectedStay == hyatt)

        viewModel.toggle(hyatt)
        #expect(viewModel.selectedStay == nil)
    }

    @Test func aTripKeepsItsBudgetWhenSaved() throws {
        let container = try ModelContainer(
            for: Trip.self, TripDay.self, TripActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let budget = TripBudget(amounts: [.stay: 400, .food: 300, .fun: 200, .gettingAround: 100], currencyCode: "EUR")
        let trip = Self.trip(budget: budget)
        context.insert(trip)
        try context.save()

        let saved = try #require(try context.fetch(FetchDescriptor<Trip>()).first)
        #expect(saved.budget?.total == 1_000)
        #expect(saved.budget?.currencyCode == "EUR")
        #expect(saved.budget == budget)
        #expect(abs((saved.budget?.amount(for: .stay) ?? 0) - 400) < 0.001)

        saved.budget = nil
        #expect(saved.budgetTotal == nil)
        #expect(saved.budget == nil)
    }
}
