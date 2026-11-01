import Foundation

// MARK: - RestaurantCuisineClassifying

/// Names the cuisine of restaurants whose map data doesn't say.
protocol RestaurantCuisineClassifying: Sendable {
    /// Cuisine labels from `RestaurantCuisineVocabulary`, keyed by restaurant
    /// ID. Restaurants it isn't confident about are left out.
    func cuisines(
        for restaurants: [CityRestaurant],
        in city: CityModel
    ) async -> [CityRestaurant.ID: String]
}
