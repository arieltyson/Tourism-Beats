import Foundation

protocol CityActivityProviding: Sendable {
    func activities(for city: CityModel) async -> [CityActivity]
}
