import Foundation

struct StagedRestaurantMealPhoto: Identifiable, Hashable {
    let photoIdentifier: UUID
    let relativePath: String

    var id: UUID { self.photoIdentifier }
}
