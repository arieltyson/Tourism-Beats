import SwiftUI

// MARK: - TripBudgetCategory

/// What a trip's budget is spent on.
enum TripBudgetCategory: String, CaseIterable, Identifiable, Sendable {
    case stay
    case food
    case fun
    case gettingAround

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .stay: String(localized: "Stay")
        case .food: String(localized: "Food")
        case .fun: String(localized: "Fun")
        case .gettingAround: String(localized: "Getting Around")
        }
    }

    var systemImage: String {
        switch self {
        case .stay: "bed.double.fill"
        case .food: "fork.knife"
        case .fun: "ticket.fill"
        case .gettingAround: "tram.fill"
        }
    }

    var color: Color {
        switch self {
        case .stay: AppColors.violet
        case .food: AppColors.coral
        case .fun: AppColors.gold
        case .gettingAround: AppColors.info
        }
    }

    /// Whether the category is spent by the night rather than by the day.
    var isNightly: Bool {
        self == .stay
    }
}
