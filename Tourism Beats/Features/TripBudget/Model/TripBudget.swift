import Foundation

// MARK: - TripBudget

/// How much a trip may cost, and how that total is split between what it's
/// spent on.
///
/// The split is kept as shares of the total, so changing the total keeps the
/// split, and changing one category's amount rebalances the others to keep
/// the total.
struct TripBudget: Hashable, Sendable {
    private(set) var total: Double
    let currencyCode: String
    private(set) var shares: [TripBudgetCategory: Double]

    init(total: Double, currencyCode: String, shares: [TripBudgetCategory: Double]) {
        self.total = max(total, 0)
        self.currencyCode = currencyCode
        self.shares = Self.normalized(shares)
    }

    /// A budget whose categories are each the given amount.
    init(amounts: [TripBudgetCategory: Double], currencyCode: String) {
        let total = amounts.values.reduce(0, +)
        self.init(
            total: total,
            currencyCode: currencyCode,
            shares: amounts.mapValues { total > 0 ? $0 / total : 0 }
        )
    }

    // MARK: Reading

    func share(of category: TripBudgetCategory) -> Double {
        self.shares[category] ?? 0
    }

    func amount(for category: TripBudgetCategory) -> Double {
        self.total * self.share(of: category)
    }

    /// The category's amount for each night or day it covers.
    func amount(for category: TripBudgetCategory, per length: TripLength) -> Double {
        let count = category.isNightly ? length.nights : length.days
        return self.amount(for: category) / Double(max(count, 1))
    }

    // MARK: Changing

    /// Sets the total, keeping the split.
    mutating func setTotal(_ total: Double) {
        self.total = max(total, 0)
    }

    /// Sets one category's amount and rebalances the others in proportion,
    /// so the total stays the same. Where the others have nothing yet, the
    /// rest is split evenly between them.
    mutating func setAmount(_ amount: Double, for category: TripBudgetCategory) {
        guard self.total > 0 else { return }
        let share = min(max(amount / self.total, 0), 1)
        let others = TripBudgetCategory.allCases.filter { $0 != category }
        let othersShare = others.reduce(0) { $0 + self.share(of: $1) }
        let remainder = 1 - share

        var shares = [category: share]
        for other in others {
            shares[other] = othersShare > 0
                ? self.share(of: other) / othersShare * remainder
                : remainder / Double(others.count)
        }
        self.shares = shares
    }

    // MARK: Equality

    /// How far apart two shares may be and still count as the same split,
    /// so a budget read back from storage equals the one saved.
    static let shareTolerance = 1e-9

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.currencyCode == rhs.currencyCode
            && lhs.total == rhs.total
            && TripBudgetCategory.allCases.allSatisfy {
                abs(lhs.share(of: $0) - rhs.share(of: $0)) <= Self.shareTolerance
            }
    }

    func hash(into hasher: inout Hasher) {
        // Shares are left out: equal budgets may differ in their last bits.
        hasher.combine(self.currencyCode)
        hasher.combine(self.total)
    }

    // MARK: Private

    /// Shares that add up to one, spread evenly when there are none.
    private static func normalized(_ shares: [TripBudgetCategory: Double]) -> [TripBudgetCategory: Double] {
        let clamped = shares.mapValues { max($0, 0) }
        let sum = clamped.values.reduce(0, +)
        guard sum > 0 else {
            let even = 1 / Double(TripBudgetCategory.allCases.count)
            return Dictionary(uniqueKeysWithValues: TripBudgetCategory.allCases.map { ($0, even) })
        }
        return Dictionary(uniqueKeysWithValues: TripBudgetCategory.allCases.map { ($0, (clamped[$0] ?? 0) / sum) })
    }
}
