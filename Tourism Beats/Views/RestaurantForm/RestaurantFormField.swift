import Foundation

// MARK: - RestaurantFormField

/// The restaurant form's text fields, in the order Return moves through them.
enum RestaurantFormField: Hashable {
    case name
    case bestDish
    case locationLink
    case menuLink
    case notes
}
