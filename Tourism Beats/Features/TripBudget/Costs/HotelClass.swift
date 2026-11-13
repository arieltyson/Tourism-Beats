// MARK: - HotelClass

/// The kind of place a nightly budget affords.
enum HotelClass: Int, CaseIterable, Comparable, Sendable {
    case hostel
    case budget
    case midRange
    case boutique
    case luxury

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// What Apple Maps is asked for.
    var searchQuery: String {
        switch self {
        case .hostel: String(localized: "Hostels")
        case .budget: String(localized: "Budget hotels")
        case .midRange: String(localized: "Hotels")
        case .boutique: String(localized: "Boutique hotels")
        case .luxury: String(localized: "Luxury hotels")
        }
    }

    /// The lowest nightly rate, in US dollars in a high-cost country, at
    /// which a traveller would usually book this class.
    var typicalNightlyFloor: Double {
        switch self {
        case .hostel: 0
        case .budget: 60
        case .midRange: 120
        case .boutique: 240
        case .luxury: 450
        }
    }

    /// The class a nightly amount, in US dollars in a high-cost country, affords.
    static func affordable(withNightly amount: Double) -> HotelClass {
        Self.allCases.last { amount >= $0.typicalNightlyFloor } ?? .hostel
    }
}
