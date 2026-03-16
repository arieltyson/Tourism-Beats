import Foundation
import SwiftData

@Model
final class RestaurantMealPhoto {
    var photoIdentifier: UUID = UUID()
    /// Legacy foreign key used by older builds before the relationship-based
    /// model ownership shipped.
    var restaurantIdentifier: UUID = UUID()
    var relativePath: String = ""
    var dateAdded: Date = Date.now
    var restaurant: Restaurant?

    init(
        photoIdentifier: UUID = UUID(),
        restaurantIdentifier: UUID,
        relativePath: String,
        dateAdded: Date = Date.now,
        restaurant: Restaurant? = nil
    ) {
        self.photoIdentifier = photoIdentifier
        self.restaurantIdentifier = restaurantIdentifier
        self.relativePath = relativePath
        self.dateAdded = dateAdded
        self.restaurant = restaurant
    }
}
