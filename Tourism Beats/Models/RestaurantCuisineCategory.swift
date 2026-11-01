import Foundation

// MARK: - RestaurantCuisineCategory

/// The groups cuisines are listed under when choosing one, in display order.
enum RestaurantCuisineCategory: String, CaseIterable, Identifiable, Sendable {
    case drinks
    case sweets
    case dining
    case world

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .drinks:
            "Drinks"
        case .sweets:
            "Sweets"
        case .dining:
            "Dining"
        case .world:
            "World Cuisines"
        }
    }

    /// The SF Symbol shown beside cuisines in this group.
    var systemImage: String {
        switch self {
        case .drinks:
            "cup.and.saucer.fill"
        case .sweets:
            "birthday.cake.fill"
        case .dining, .world:
            "fork.knife"
        }
    }
}
