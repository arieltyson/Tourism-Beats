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
    var cuisineRaw: String?
    var bestDish: String?
    var statusRaw: String = RestaurantStatus.wantToTry.rawValue
    var locationURLString: String?
    var menuURLString: String?
    var notes: String?
    var dateAdded: Date = Date.now

    init(
        name: String,
        city: String,
        country: String,
        score: Int? = nil,
        cuisine: RestaurantCuisine? = nil,
        bestDish: String? = nil,
        status: RestaurantStatus = .wantToTry,
        locationURLString: String? = nil,
        menuURLString: String? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.city = city
        self.country = country
        self.score = score
        self.cuisineRaw = cuisine?.rawValue
        self.bestDish = bestDish
        self.statusRaw = status.rawValue
        self.locationURLString = locationURLString
        self.menuURLString = menuURLString
        self.notes = notes
        self.dateAdded = .now
    }

    /// Type-safe accessor for the restaurant's tried/want-to-try status.
    var status: RestaurantStatus {
        get { RestaurantStatus(rawValue: self.statusRaw) ?? .wantToTry }
        set { self.statusRaw = newValue.rawValue }
    }

    var cuisine: RestaurantCuisine? {
        get {
            guard let cuisineRaw else { return nil }
            return RestaurantCuisine(rawValue: cuisineRaw)
        }
        set { self.cuisineRaw = newValue?.rawValue }
    }

    var displayCuisine: RestaurantCuisine {
        self.cuisine ?? .other
    }

    var locationURL: URL? {
        guard let locationURLString else { return nil }
        return URL(string: locationURLString)
    }

    var menuURL: URL? {
        guard let menuURLString else { return nil }
        return URL(string: menuURLString)
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
