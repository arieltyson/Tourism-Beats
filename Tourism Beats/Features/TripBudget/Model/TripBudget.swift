import Foundation

// MARK: - TripBudget

/// How much a trip may cost, and how that total is split between what it's
/// spent on.
///
/// The split is kept as shares of the total. Setting a category's amount
/// locks it there: later changes rebalance only the unlocked categories, so
/// the total always holds and nothing the traveller set moves on its own.
struct TripBudget: Hashable, Sendable {
    private(set) var total: Double
    let currencyCode: String
    private(set) var shares: [TripBudgetCategory: Double]

    /// The categories whose amounts stay put, from the longest locked.
    private(set) var locked: [TripBudgetCategory]

    init(
        total: Double,
        currencyCode: String,
        shares: [TripBudgetCategory: Double],
        locked: [TripBudgetCategory] = []
    ) {
        self.total = max(total, 0)
        self.currencyCode = currencyCode
        self.shares = Self.normalized(shares)
        // Each category once, and at least one left free to take up the rest.
        let distinct = locked.reduce(into: [TripBudgetCategory]()) { if !$0.contains($1) { $0.append($1) } }
        self.locked = Array(distinct.suffix(TripBudgetCategory.allCases.count - 1))
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

    func isLocked(_ category: TripBudgetCategory) -> Bool {
        self.locked.contains(category)
    }

    /// The most the category can be set to without moving a locked category.
    func maximumAmount(for category: TripBudgetCategory) -> Double {
        let held = self.lockedOthers(whenSetting: category)
        return max(self.total - held.reduce(0) { $0 + self.amount(for: $1) }, 0)
    }

    /// Whether the category set last has stopped where the other locked
    /// categories leave no more room.
    func isHeldBack(_ category: TripBudgetCategory) -> Bool {
        guard self.locked.last == category else { return false }
        let maximum = self.maximumAmount(for: category)
        let tolerance = self.total * Self.shareTolerance
        return maximum < self.total - tolerance
            && self.amount(for: category) >= maximum - tolerance
    }

    /// The category's amount for each night or day it covers.
    func amount(for category: TripBudgetCategory, per length: TripLength) -> Double {
        let count = category.isNightly ? length.nights : length.days
        return self.amount(for: category) / Double(max(count, 1))
    }

    // MARK: Changing

    /// Sets the total. Locked categories keep their amounts and the rest
    /// share what's left; when the total can't cover the locked amounts,
    /// they're unlocked and the whole split scales instead.
    mutating func setTotal(_ total: Double) {
        let total = max(total, 0)
        let lockedAmounts = Dictionary(uniqueKeysWithValues: self.locked.map { ($0, self.amount(for: $0)) })
        let lockedSum = lockedAmounts.values.reduce(0, +)

        guard !lockedAmounts.isEmpty, total > 0, total >= lockedSum else {
            self.total = total
            self.locked = []
            return
        }

        let free = TripBudgetCategory.allCases.filter { lockedAmounts[$0] == nil }
        var shares = lockedAmounts.mapValues { $0 / total }
        shares.merge(self.split(1 - lockedSum / total, among: free)) { $1 }
        self.total = total
        self.shares = shares
    }

    /// Sets one category's amount and locks it there. Only unlocked
    /// categories make room, in proportion to what they have, so the total
    /// stays the same; the amount stops where they run out. When every other
    /// category is locked, the one locked longest gives way.
    mutating func setAmount(_ amount: Double, for category: TripBudgetCategory) {
        guard self.total > 0 else { return }
        let held = self.lockedOthers(whenSetting: category)
        let heldShare = held.reduce(0) { $0 + self.share(of: $1) }
        let share = min(max(amount / self.total, 0), 1 - heldShare)
        let free = TripBudgetCategory.allCases.filter { $0 != category && !held.contains($0) }

        var shares = Dictionary(uniqueKeysWithValues: held.map { ($0, self.share(of: $0)) })
        shares[category] = share
        shares.merge(self.split(1 - heldShare - share, among: free)) { $1 }
        self.shares = shares
        self.locked = held + [category]
    }

    /// Lets the category rebalance again.
    mutating func unlock(_ category: TripBudgetCategory) {
        self.locked.removeAll { $0 == category }
    }

    // MARK: Equality

    /// How far apart two shares may be and still count as the same split,
    /// so a budget read back from storage equals the one saved.
    static let shareTolerance = 1e-9

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.currencyCode == rhs.currencyCode
            && lhs.total == rhs.total
            && lhs.locked == rhs.locked
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

    /// The locked categories that stay put while `category` is set: all but
    /// `category` itself, less the longest locked when nothing else is free.
    private func lockedOthers(whenSetting category: TripBudgetCategory) -> [TripBudgetCategory] {
        let others = self.locked.filter { $0 != category }
        let freeCount = TripBudgetCategory.allCases.count - 1 - others.count
        return freeCount > 0 ? others : Array(others.dropFirst())
    }

    /// Splits a share between categories in proportion to what they have,
    /// or evenly when they have nothing.
    private func split(_ share: Double, among categories: [TripBudgetCategory]) -> [TripBudgetCategory: Double] {
        let current = categories.reduce(0) { $0 + self.share(of: $1) }
        return Dictionary(uniqueKeysWithValues: categories.map { category in
            let portion = current > 0
                ? self.share(of: category) / current
                : 1 / Double(categories.count)
            return (category, share * portion)
        })
    }

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
