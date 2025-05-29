import CoreLocation
import Foundation
import WeatherKit

enum WeatherError: Error {
    case fetchFailed(Error)
}

class WeatherFetcherService {
    private let weatherService = WeatherService.shared

    func fetchWeather(at coordinate: CLLocationCoordinate2D) async throws
        -> Weather
    {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        do {
            return try await weatherService.weather(for: location)
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }
}
