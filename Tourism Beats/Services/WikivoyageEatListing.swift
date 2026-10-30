import Foundation

// MARK: - WikivoyageEatListing

/// A restaurant recommended in a city's Wikivoyage guide. Travel guide
/// editors curate these, which makes them free, independent evidence of a
/// good place to eat.
struct WikivoyageEatListing: Sendable, Equatable {
    let name: String
    let alternateName: String?
    let latitude: Double?
    let longitude: Double?
}
