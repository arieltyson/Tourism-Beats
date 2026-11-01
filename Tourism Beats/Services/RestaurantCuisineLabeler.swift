import Foundation

// MARK: - RestaurantCuisineLabeler

/// Gives every restaurant in a guide a cuisine label where one can be found.
enum RestaurantCuisineLabeler {
    /// The restaurants with any missing cuisines filled in by the classifier.
    /// Labels the map data already provided are kept as they are.
    static func label(
        _ restaurants: [CityRestaurant],
        in city: CityModel,
        using classifier: any RestaurantCuisineClassifying
    ) async -> [CityRestaurant] {
        let unlabelled = restaurants.filter { $0.cuisine == nil }
        guard !unlabelled.isEmpty else { return restaurants }

        let labels = await classifier.cuisines(for: unlabelled, in: city)
        guard !labels.isEmpty else { return restaurants }

        return restaurants.map { restaurant in
            guard restaurant.cuisine == nil, let label = labels[restaurant.id] else { return restaurant }
            var labelled = restaurant
            labelled.cuisine = label
            return labelled
        }
    }

    /// Whether any restaurant still lacks a cuisine.
    static func hasUnlabelled(_ restaurants: [CityRestaurant]) -> Bool {
        restaurants.contains { $0.cuisine == nil }
    }
}
