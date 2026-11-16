import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - TripBudgetTests

struct TripBudgetTests {
    private static func evenBudget(total: Double = 1_000) -> TripBudget {
        TripBudget(
            total: total,
            currencyCode: "USD",
            shares: [.stay: 1, .food: 1, .fun: 1, .gettingAround: 1]
        )
    }

    private static func sum(_ budget: TripBudget) -> Double {
        TripBudgetCategory.allCases.reduce(0) { $0 + budget.amount(for: $1) }
    }

    @Test func sharesAreNormalizedToTheTotal() {
        let budget = Self.evenBudget()

        #expect(budget.amount(for: .food) == 250)
        #expect(abs(Self.sum(budget) - 1_000) < 0.001)
    }

    @Test func changingOneCategoryRebalancesTheOthersInProportion() {
        var budget = TripBudget(
            total: 1_000,
            currencyCode: "USD",
            shares: [.stay: 0.4, .food: 0.3, .fun: 0.2, .gettingAround: 0.1]
        )

        budget.setAmount(700, for: .stay)

        #expect(abs(budget.amount(for: .stay) - 700) < 0.001)
        // The other 300 keeps their 3 : 2 : 1 split.
        #expect(abs(budget.amount(for: .food) - 150) < 0.001)
        #expect(abs(budget.amount(for: .fun) - 100) < 0.001)
        #expect(abs(budget.amount(for: .gettingAround) - 50) < 0.001)
        #expect(abs(Self.sum(budget) - 1_000) < 0.001)
    }

    @Test func freeingTheWholeTotalSpreadsItEvenlyWhenTheOthersHadNothing() {
        var budget = Self.evenBudget()
        budget.setAmount(1_000, for: .stay)
        budget.setAmount(400, for: .stay)

        for category in [TripBudgetCategory.food, .fun, .gettingAround] {
            #expect(abs(budget.amount(for: category) - 200) < 0.001)
        }
    }

    @Test func amountsAreClampedToTheTotal() {
        var budget = Self.evenBudget()
        budget.setAmount(5_000, for: .fun)

        #expect(abs(budget.amount(for: .fun) - 1_000) < 0.001)
        #expect(budget.amount(for: .food) == 0)
    }

    @Test func changingTheTotalKeepsTheSplit() {
        var budget = Self.evenBudget()
        budget.setTotal(2_000)

        #expect(budget.amount(for: .stay) == 500)
    }

    // MARK: Locking

    private static func isClose(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.001
    }

    @Test func aCategoryYouSetStaysPutWhileOthersMove() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.setAmount(500, for: .stay)

        #expect(Self.isClose(budget.amount(for: .food), 200))
        #expect(Self.isClose(budget.amount(for: .stay), 500))
        #expect(Self.isClose(budget.amount(for: .fun) + budget.amount(for: .gettingAround), 300))
        #expect(budget.locked == [.food, .stay])
    }

    @Test func aCategoryStopsWhereTheLockedOnesLeaveNoRoom() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.setAmount(500, for: .stay)
        budget.setAmount(900, for: .fun)

        #expect(Self.isClose(budget.amount(for: .fun), 300))
        #expect(Self.isClose(budget.amount(for: .gettingAround), 0))
        #expect(Self.isClose(Self.sum(budget), 1_000))
        #expect(budget.isHeldBack(.fun))
        #expect(!budget.isHeldBack(.food))
    }

    @Test func whenEveryOtherCategoryIsLockedTheLongestLockedGivesWay() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.setAmount(300, for: .stay)
        budget.setAmount(100, for: .fun)

        budget.setAmount(500, for: .gettingAround)

        #expect(Self.isClose(budget.amount(for: .stay), 300))
        #expect(Self.isClose(budget.amount(for: .fun), 100))
        #expect(Self.isClose(budget.amount(for: .food), 100))
        #expect(budget.locked == [.stay, .fun, .gettingAround])
    }

    @Test func anUnlockedCategoryRebalancesAgain() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.unlock(.food)
        budget.setAmount(1_000, for: .stay)

        #expect(budget.amount(for: .food) == 0)
        #expect(!budget.isLocked(.food))
    }

    @Test func changingTheTotalKeepsLockedAmounts() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.setTotal(2_000)

        #expect(Self.isClose(budget.amount(for: .food), 200))
        #expect(Self.isClose(Self.sum(budget), 2_000))
        #expect(budget.isLocked(.food))
    }

    @Test func aTotalTooSmallForTheLockedAmountsUnlocksThemAndScales() {
        var budget = Self.evenBudget()
        budget.setAmount(700, for: .food)
        budget.setTotal(500)

        #expect(budget.locked.isEmpty)
        #expect(Self.isClose(budget.amount(for: .food), 350))
    }

    @Test func atLeastOneCategoryIsAlwaysLeftFree() {
        let budget = TripBudget(
            total: 1_000,
            currencyCode: "USD",
            shares: [:],
            locked: [.food, .food, .stay, .fun, .gettingAround]
        )

        #expect(budget.locked == [.stay, .fun, .gettingAround])
    }

    @Test func locksAreSavedWithTheTrip() {
        var budget = Self.evenBudget()
        budget.setAmount(200, for: .food)
        budget.setAmount(400, for: .stay)
        let trip = Trip(name: "Osaka", city: "Osaka", country: "Japan")

        trip.budget = budget

        #expect(trip.budget == budget)
        #expect(trip.budget?.locked == [.food, .stay])
    }

    @Test func staysAreCountedByTheNightAndTheRestByTheDay() {
        let budget = Self.evenBudget()
        let length = TripLength(days: 5)

        #expect(length.nights == 4)
        #expect(budget.amount(for: .stay, per: length) == 62.5)
        #expect(budget.amount(for: .food, per: length) == 50)
    }

    @Test func aDayTripStillBooksOneNight() {
        #expect(TripLength(days: 1).nights == 1)
        #expect(TripLength(days: 0).days == 1)
    }
}
