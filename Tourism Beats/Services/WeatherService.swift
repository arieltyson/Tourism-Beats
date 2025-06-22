import CoreLocation
import Foundation
@preconcurrency import WeatherKit

struct WeatherDisplayInfo: Sendable, Hashable {
    let condition: String
    let iconName: String
    let temperatureCelsius: String
    let temperatureFahrenheit: String
}

enum WeatherError: Error {
    case fetchFailed(Error)
}

@MainActor
class WeatherFetcherService {
    private let weatherService = WeatherService.shared

    func fetchWeather(at coordinate: CLLocationCoordinate2D) async throws
        -> WeatherDisplayInfo
    {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        do {
            let weather = try await weatherService.weather(for: location)
            return processWeather(weather)
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }

    private func processWeather(_ weather: Weather) -> WeatherDisplayInfo {
        let current = weather.currentWeather
        let condition = current.condition.description
        let iconName = iconName(for: current.condition)
        let tempMeasurement = current.temperature

        let tempCelsius = tempMeasurement.converted(to: .celsius)
        let tempFahrenheit = tempMeasurement.converted(to: .fahrenheit)

        let celsiusValue = Int(tempCelsius.value.rounded())
        let fahrenheitValue = Int(tempFahrenheit.value.rounded())

        let celsiusStr = "\(celsiusValue)°C"
        let fahrenheitStr = "\(fahrenheitValue)°F"

        return .init(
            condition: condition,
            iconName: iconName,
            temperatureCelsius: celsiusStr,
            temperatureFahrenheit: fahrenheitStr
        )
    }

    private func iconName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .mostlyClear, .partlyCloudy, .mostlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .haze: return "sun.haze.fill"
        case .drizzle, .rain: return "cloud.rain.fill"
        case .thunderstorms: return "cloud.bolt.fill"
        case .snow, .sleet, .freezingRain, .hail: return "snow"
        case .blizzard, .blowingSnow: return "wind.snow"
        case .blowingDust: return "sun.dust.fill"
        case .breezy, .windy: return "wind"
        case .hot: return "sun.max.fill"
        case .flurries, .sunFlurries: return "cloud.snow.fill"
        case .frigid: return "thermometer.snowflake"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .hurricane, .tropicalStorm: return "hurricane"
        case .isolatedThunderstorms, .scatteredThunderstorms:
            return "cloud.sun.bolt.fill"
        case .smoky: return "smoke.fill"
        default: return "cloud"
        }
    }
}
