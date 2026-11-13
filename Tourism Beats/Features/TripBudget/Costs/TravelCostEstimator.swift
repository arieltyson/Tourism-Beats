import Foundation

// MARK: - TravelCostEstimator

/// Estimates what a trip typically costs, and what kind of hotel a budget
/// affords, from where it's headed.
struct TravelCostEstimator: Sendable {
    /// What a traveller typically spends, in US dollars in a high-cost
    /// country: a mid-range room each night, and each day's meals, sights,
    /// and local transport.
    static let typicalDollarSpend: [TripBudgetCategory: Double] = [
        .stay: 160,
        .food: 70,
        .fun: 40,
        .gettingAround: 20
    ]

    /// The currency budgets fall back to when the traveller's isn't known.
    static let fallbackCurrencyCode = "USD"

    let reference: TravelCostReference

    init(reference: TravelCostReference = .shared) {
        self.reference = reference
    }

    /// The currency a budget is kept in: the one given where its rate is
    /// known, and US dollars otherwise.
    func budgetCurrency(preferring currencyCode: String?) -> String {
        guard let currencyCode, self.reference.dollarRate(for: currencyCode) != nil else {
            return Self.fallbackCurrencyCode
        }
        return currencyCode.uppercased()
    }

    /// A typical budget for a trip of `length` to the country, in `currencyCode`.
    func typicalBudget(
        for length: TripLength,
        countryCode: String,
        currencyCode: String
    ) -> TripBudget {
        let currency = self.budgetCurrency(preferring: currencyCode)
        let scale = self.reference.costLevel(forCountryCode: countryCode).priceMultiplier
            * (self.reference.dollarRate(for: currency) ?? 1)

        let amounts = Dictionary(uniqueKeysWithValues: TripBudgetCategory.allCases.map { category in
            let count = category.isNightly ? length.nights : length.days
            let spend = (Self.typicalDollarSpend[category] ?? 0) * Double(count) * scale
            return (category, Self.rounded(spend))
        })
        return TripBudget(amounts: amounts, currencyCode: currency)
    }

    /// The kind of hotel the budget's stay affords each night in the country.
    func hotelClass(for budget: TripBudget, length: TripLength, countryCode: String) -> HotelClass {
        let nightly = budget.amount(for: .stay, per: length)
        let rate = self.reference.dollarRate(for: budget.currencyCode) ?? 1
        let multiplier = self.reference.costLevel(forCountryCode: countryCode).priceMultiplier
        return HotelClass.affordable(withNightly: nightly / rate / multiplier)
    }

    /// Rounds an estimate to two significant figures, as people say prices.
    static func rounded(_ amount: Double) -> Double {
        guard amount >= 10 else { return amount.rounded() }
        let magnitude = pow(10, floor(log10(amount)) - 1)
        return (amount / magnitude).rounded() * magnitude
    }
}
