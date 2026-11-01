import Foundation

// MARK: - RestaurantPlace

/// A city a restaurant can be in, with the country it belongs to.
struct RestaurantPlace: Identifiable, Hashable, Sendable {
    let city: String
    let country: String
    var flag: String?
    /// Other names the city is searched by, such as "Santorini" for Fira.
    var searchAliases: [String] = []

    var id: String {
        FoodJournalCityGroup.groupKey(city: self.city, country: self.country)
    }
}
