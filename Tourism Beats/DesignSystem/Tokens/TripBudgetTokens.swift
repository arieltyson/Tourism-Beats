import CoreGraphics

// MARK: - TripBudgetTokens

/// The look of a trip's budget.
enum TripBudgetTokens {
    /// The ring's height at the default text size; it scales with Dynamic Type.
    static let chartHeight: CGFloat = 200
    /// How much of the ring's radius is left open for the total.
    static let chartInnerRadiusRatio: CGFloat = 0.68
    /// The gap between neighbouring categories in the ring.
    static let sectorInset: CGFloat = 2
    static let sectorCornerRadius: CGFloat = 4
}
