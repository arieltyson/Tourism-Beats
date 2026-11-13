// MARK: - CountryCostLevel

/// How expensive a country is for a visitor, in broad bands.
///
/// Bands, rather than precise indices, because prices move and vary within a
/// country; they're enough to suggest a sensible budget and the kind of hotel
/// it affords. They follow the World Bank's price level indices.
enum CountryCostLevel: String, Codable, CaseIterable, Sendable {
    case veryLow
    case low
    case moderate
    case high
    case veryHigh

    /// Prices here relative to a high-cost country such as the United States.
    var priceMultiplier: Double {
        switch self {
        case .veryLow: 0.35
        case .low: 0.5
        case .moderate: 0.75
        case .high: 1
        case .veryHigh: 1.35
        }
    }
}
