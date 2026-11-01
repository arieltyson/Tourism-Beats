import Foundation
import FoundationModels

// MARK: - GeneratedRestaurantCuisines

/// The on-device model's answer: one cuisine per restaurant, in list order.
@Generable
struct GeneratedRestaurantCuisines {
    @Guide(description: "One entry for each restaurant, in the same order as the list.")
    var restaurants: [GeneratedRestaurantCuisine]
}

// MARK: - GeneratedRestaurantCuisine

@Generable
struct GeneratedRestaurantCuisine {
    @Guide(description: "The restaurant's number from the list.")
    var number: Int

    @Guide(
        description: "The cuisine the restaurant is best known for, or Unknown.",
        .anyOf(OnDeviceRestaurantCuisineClassifier.choices)
    )
    var cuisine: String
}
