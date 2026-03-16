import Foundation
import SwiftData

// MARK: - Restaurant

/// A user-created restaurant entry for the Food Journal.
///
/// All stored properties use defaults or optionals to satisfy CloudKit sync
/// requirements. The `statusRaw` string backs a type-safe computed `status`
/// property.
@Model
final class Restaurant {
    var name: String = ""
    var city: String = ""
    var country: String = ""
    var score: Int?
    var bestDish: String?
    var statusRaw: String = RestaurantStatus.wantToTry.rawValue
    var notes: String?
    var dateAdded: Date = Date.now

    init(
        name: String,
        city: String,
        country: String,
        score: Int? = nil,
        bestDish: String? = nil,
        status: RestaurantStatus = .wantToTry,
        notes: String? = nil
    ) {
        self.name = name
        self.city = city
        self.country = country
        self.score = score
        self.bestDish = bestDish
        self.statusRaw = status.rawValue
        self.notes = notes
        self.dateAdded = .now
    }

    /// Type-safe accessor for the restaurant's tried/want-to-try status.
    var status: RestaurantStatus {
        get { RestaurantStatus(rawValue: self.statusRaw) ?? .wantToTry }
        set { self.statusRaw = newValue.rawValue }
    }

    /// Clamped score guaranteed to be within 0…10 range.
    var clampedScore: Int? {
        guard let score else { return nil }
        return min(max(score, 0), 10)
    }
}

// MARK: - RestaurantStatus

/// The user's relationship with a restaurant: visited or aspirational.
enum RestaurantStatus: String, CaseIterable, Identifiable, Sendable {
    case wantToTry
    case tried

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .wantToTry: "Want to Try"
        case .tried: "Tried"
        }
    }

    var systemImage: String {
        switch self {
        case .wantToTry: "star"
        case .tried: "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .wantToTry: "coral"
        case .tried: "safe"
        }
    }
}
