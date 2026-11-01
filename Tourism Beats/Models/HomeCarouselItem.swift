import Foundation

// MARK: - HomeCarouselItem

/// One card in the home carousel. Cities return once the deck has gone round,
/// so each card carries its own position as its identity.
struct HomeCarouselItem: Identifiable, Hashable {
    let id: Int
    let city: CityModel
}
