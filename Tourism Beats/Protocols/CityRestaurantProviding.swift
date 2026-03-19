import Foundation

protocol CityRestaurantProviding: Sendable {
    func restaurants(for city: CityModel) async -> [CityRestaurant]
}
