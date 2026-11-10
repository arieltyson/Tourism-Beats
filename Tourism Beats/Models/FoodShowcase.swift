import Foundation

// MARK: - FoodShowcase

/// A ranking the Food tab can show in place of the journal.
enum FoodShowcase: String, CaseIterable, Identifiable, Sendable {
    case topCuisines
    case gastroCities

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .topCuisines: String(localized: "Top Cuisines")
        case .gastroCities: String(localized: "Top Gastro Cities")
        }
    }

    var systemImage: String {
        switch self {
        case .topCuisines: "trophy"
        case .gastroCities: "building.2"
        }
    }
}
