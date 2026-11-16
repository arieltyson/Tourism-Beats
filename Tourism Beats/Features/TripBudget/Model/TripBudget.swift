import Foundation

// MARK: - TripBudget

/// How much a trip may cost, and how that total is split between what it's
/// spent on.
///
/// Each category's amount is kept as a share of the total. The traveller can
/// lock any categories they like; a locked category never moves unless they
/// unlock it. Changing a category rebalances only the unlocked ones, and when
/// they can't make room, the split runs over the total rather than touching a
/// lock, and `overage` says by how much.
struct TripBudget: Hashable, Sendable {
    private(set) var total: Double
    let currencyCode: String
    private(set) var shares: [TripBudgetCategory: Double]

    /// The categories the traveller has locked.
    private(set) var locked: Set<TripBudgetCategory>

    /// A budget split between its categories in proportion to `shares`.
    init(
        total: Double,
        currencyCode: String,
        shares: [TripBudgetCategory: Double],
        locked: Set<TripBudgetCategory> = []
    ) {
        self.init(
            total: total,
            currencyCode: currencyCode,
            fractions: Self.normalized(shares),
            locked: locked
        )
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

    /// A budget whose categories are each the given fraction of the total,
    /// kept as they are, so a split that runs over the total stays over it.
    init(
        total: Double,
        currencyCode: String,
        fractions: [TripBudgetCategory: Double],
        locked: Set<TripBudgetCategory>
    ) {
        let fractions = fractions.mapValues { max($0, 0) }
        let isEmpty = fractions.values.allSatisfy { $0 == 0 }
        self.total = max(total, 0)
        self.currencyCode = currencyCode
        self.shares = isEmpty ? Self.normalized([:]) : fractions
        self.locked = locked
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

    /// How far the categories together run over the total; zero within it.
    var overage: Double {
        let allocated = TripBudgetCategory.allCases.reduce(0) { $0 + self.amount(for: $1) }
        let overage = allocated - self.total
        return overage > self.total * Self.shareTolerance ? overage : 0
    }

    /// Whether the category is the one taking the split over the total: the
    /// unlocked category that still has an amount, or, when only locked
    /// categories have one, those.
    func isOverBudget(_ category: TripBudgetCategory) -> Bool {
        guard self.overage > 0, self.amount(for: category) > 0 else { return false }
        let unlockedWithAmounts = TripBudgetCategory.allCases.filter {
            !self.isLocked($0) && self.amount(for: $0) > 0
        }
        return unlockedWithAmounts.isEmpty ? self.isLocked(category) : !self.isLocked(category)
    }

    /// The category's amount for each night or day it covers.
    func amount(for category: TripBudgetCategory, per length: TripLength) -> Double {
        let count = category.isNightly ? length.nights : length.days
        return self.amount(for: category) / Double(max(count, 1))
    }

    /// Whether the two budgets hold the same amounts, however they're locked.
    func hasSameAmounts(as other: Self) -> Bool {
        self.currencyCode == other.currencyCode
            && self.total == other.total
            && TripBudgetCategory.allCases.allSatisfy {
                abs(self.share(of: $0) - other.share(of: $0)) <= Self.shareTolerance
            }
    }

    /// This budget's locks on `other`'s amounts.
    func keepingLocks(on other: Self) -> Self {
        Self(total: other.total, currencyCode: other.currencyCode, fractions: other.shares, locked: self.locked)
    }

    // MARK: Changing

    /// Sets the total. Locked categories keep their amounts and the unlocked
    /// ones share what's left, in proportion; with nothing left, the locked
    /// amounts run over the total.
    mutating func setTotal(_ total: Double) {
        let total = max(total, 0)
        guard !self.locked.isEmpty, total > 0 else {
            self.total = total
            return
        }

        var shares = Dictionary(uniqueKeysWithValues: self.locked.map { ($0, self.amount(for: $0) / total) })
        let lockedShare = shares.values.reduce(0, +)
        shares.merge(self.split(max(1 - lockedShare, 0), among: self.unlocked(except: nil))) { $1 }
        self.total = total
        self.shares = shares
    }

    /// Sets one category's amount, up to the total. The other unlocked
    /// categories make room, in proportion to what they have; locked ones
    /// never move. Past what the unlocked ones can give, the split runs over
    /// the total.
    mutating func setAmount(_ amount: Double, for category: TripBudgetCategory) {
        guard self.total > 0 else { return }
        let share = min(max(amount / self.total, 0), 1)
        let others = self.unlocked(except: category)
        let fixedShare = TripBudgetCategory.allCases
            .filter { $0 != category && !others.contains($0) }
            .reduce(0) { $0 + self.share(of: $1) }

        var shares = self.shares
        shares[category] = share
        shares.merge(self.split(max(1 - fixedShare - share, 0), among: others)) { $1 }
        self.shares = shares
    }

    /// Locks the category, or unlocks it.
    mutating func toggleLock(_ category: TripBudgetCategory) {
        if self.locked.remove(category) == nil {
            self.locked.insert(category)
        }
    }

    // MARK: Equality

    /// How far apart two shares may be and still count as the same split,
    /// so a budget read back from storage equals the one saved.
    static let shareTolerance = 1e-9

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.locked == rhs.locked && lhs.hasSameAmounts(as: rhs)
    }

    func hash(into hasher: inout Hasher) {
        // Shares are left out: equal budgets may differ in their last bits.
        hasher.combine(self.currencyCode)
        hasher.combine(self.total)
        hasher.combine(self.locked)
    }

    // MARK: Private

    /// The unlocked categories, other than `category`.
    private func unlocked(except category: TripBudgetCategory?) -> [TripBudgetCategory] {
        TripBudgetCategory.allCases.filter { $0 != category && !self.isLocked($0) }
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
