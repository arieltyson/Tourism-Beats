import Foundation

protocol CityFunFactProviding: Sendable {
    func facts(for city: CityModel) async -> [CityFunFact]
}
