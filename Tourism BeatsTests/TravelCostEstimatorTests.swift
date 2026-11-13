import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - TravelCostEstimatorTests

struct TravelCostEstimatorTests {
    private let estimator = TravelCostEstimator(
        reference: TravelCostReference(
            costLevels: ["US": .high, "IN": .veryLow, "CH": .veryHigh],
            dollarRates: ["EUR": 0.9]
        )
    )

    @Test func aTypicalBudgetCountsNightsForTheStayAndDaysForTheRest() {
        let budget = self.estimator.typicalBudget(for: TripLength(days: 3), countryCode: "US", currencyCode: "USD")

        #expect(budget.amount(for: .stay).rounded() == 320)
        #expect(budget.amount(for: .food).rounded() == 210)
        #expect(budget.amount(for: .fun).rounded() == 120)
        #expect(budget.amount(for: .gettingAround).rounded() == 60)
    }

    @Test func cheaperCountriesCostLess() {
        let length = TripLength(days: 5)
        let india = self.estimator.typicalBudget(for: length, countryCode: "IN", currencyCode: "USD")
        let switzerland = self.estimator.typicalBudget(for: length, countryCode: "CH", currencyCode: "USD")

        #expect(india.total < switzerland.total)
    }

    @Test func aBudgetIsKeptInTheTravellersCurrencyWhenItsRateIsKnown() {
        let euros = self.estimator.typicalBudget(for: TripLength(days: 2), countryCode: "US", currencyCode: "eur")
        let unknown = self.estimator.typicalBudget(for: TripLength(days: 2), countryCode: "US", currencyCode: "XYZ")

        #expect(euros.currencyCode == "EUR")
        #expect(unknown.currencyCode == "USD")
    }

    @Test func unknownCountriesCountAsModerate() {
        let reference = TravelCostReference(costLevels: [:], dollarRates: [:])

        #expect(reference.costLevel(forCountryCode: "ZZ") == .moderate)
    }

    @Test(arguments: [
        (40.0, HotelClass.hostel),
        (90.0, .budget),
        (160.0, .midRange),
        (300.0, .boutique),
        (600.0, .luxury)
    ])
    func aNightlyStayBudgetAffordsItsHotelClass(nightly: Double, expected: HotelClass) {
        let budget = TripBudget(amounts: [.stay: nightly, .food: 0, .fun: 0, .gettingAround: 0], currencyCode: "USD")

        // One day books one night, so the stay is the whole nightly amount.
        #expect(self.estimator.hotelClass(for: budget, length: TripLength(days: 1), countryCode: "US") == expected)
    }

    @Test func theSameNightlyBudgetAffordsMoreWhereThingsCostLess() {
        let budget = TripBudget(amounts: [.stay: 90, .food: 0, .fun: 0, .gettingAround: 0], currencyCode: "USD")
        let length = TripLength(days: 1)

        #expect(
            self.estimator.hotelClass(for: budget, length: length, countryCode: "IN")
                > self.estimator.hotelClass(for: budget, length: length, countryCode: "US")
        )
    }

    @Test(arguments: [(7.4, 7.0), (1_234.0, 1_200.0), (98_765.0, 99_000.0)])
    func estimatesAreRoundedAsPeopleSayPrices(amount: Double, expected: Double) {
        #expect(TravelCostEstimator.rounded(amount) == expected)
    }

    @MainActor @Test func theBundledReferenceCoversEveryCatalogCountry() throws {
        let reference = TravelCostReference(bundle: .main)
        let countries = try DataService().loadCountries()

        #expect(countries.allSatisfy { reference.costLevels[$0.code] != nil })
        #expect(reference.dollarRate(for: "EUR") != nil)
    }
}
