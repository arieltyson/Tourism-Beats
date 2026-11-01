import Foundation

// MARK: - ActivityType + Place

extension ActivityType {
    /// Whether activities of this type happen at a named place, such as a
    /// sight or a restaurant, that a map search can find by name.
    var isPlace: Bool {
        switch self {
        case .accommodation, .attraction, .food, .nightlife, .shopping:
            true
        case .flight, .other, .transport, .wakeUp:
            false
        }
    }
}
