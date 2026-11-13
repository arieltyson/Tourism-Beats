import Foundation

// MARK: - Trip+Budget

extension Trip {
    /// The trip's budget, kept in plain fields so trips saved before budgets
    /// existed migrate without a schema change.
    var budget: TripBudget? {
        get {
            guard let budgetTotal, let budgetCurrencyCode else { return nil }
            return TripBudget(
                total: budgetTotal,
                currencyCode: budgetCurrencyCode,
                shares: [
                    .stay: self.budgetStayShare ?? 0,
                    .food: self.budgetFoodShare ?? 0,
                    .fun: self.budgetFunShare ?? 0,
                    .gettingAround: self.budgetGettingAroundShare ?? 0
                ]
            )
        }
        set {
            self.budgetTotal = newValue?.total
            self.budgetCurrencyCode = newValue?.currencyCode
            self.budgetStayShare = newValue?.share(of: .stay)
            self.budgetFoodShare = newValue?.share(of: .food)
            self.budgetFunShare = newValue?.share(of: .fun)
            self.budgetGettingAroundShare = newValue?.share(of: .gettingAround)
        }
    }

    /// How long the trip runs, by its itinerary days.
    var length: TripLength {
        TripLength(days: self.dayCount)
    }
}
