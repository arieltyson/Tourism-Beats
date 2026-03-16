import Foundation
import SwiftData

@Model
final class RestaurantMealPhoto {
    var photoIdentifier: UUID = UUID()
    var restaurantIdentifier: UUID = UUID()
    var relativePath: String = ""
    var dateAdded: Date = Date.now

    init(
        photoIdentifier: UUID = UUID(),
        restaurantIdentifier: UUID,
        relativePath: String,
        dateAdded: Date = Date.now
    ) {
        self.photoIdentifier = photoIdentifier
        self.restaurantIdentifier = restaurantIdentifier
        self.relativePath = relativePath
        self.dateAdded = dateAdded
    }
}
