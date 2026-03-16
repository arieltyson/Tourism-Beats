import CoreLocation
import Foundation
@preconcurrency import WeatherKit

// MARK: - WeatherDisplayInfo

struct WeatherDisplayInfo: Sendable, Hashable {
    let condition: String
    let iconName: String
    let temperatureCelsius: String
    let temperatureFahrenheit: String
}

// MARK: - WeatherError

enum WeatherError: Error {
    case fetchFailed(Error)
}

// MARK: - WeatherFetcherService

@MainActor
class WeatherFetcherService {
    private let weatherService = WeatherService.shared

    private static let temperatureFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.locale = .current
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    func fetchWeather(at coordinate: CLLocationCoordinate2D) async throws
    -> WeatherDisplayInfo
    {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        do {
            let weather = try await weatherService.weather(for: location)
            return self.processWeather(weather)
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }

    private func processWeather(_ weather: Weather) -> WeatherDisplayInfo {
        let current = weather.currentWeather
        let condition = current.condition.description
        let iconName = iconName(for: current.condition)

        let original = current.temperature
        let inCelsius = original.converted(to: .celsius)
        let inFahrenheit = original.converted(to: .fahrenheit)

        let roundedC = Measurement(
            value: inCelsius.value.rounded(),
            unit: UnitTemperature.celsius
        )
        let roundedF = Measurement(
            value: inFahrenheit.value.rounded(),
            unit: UnitTemperature.fahrenheit
        )

        let celsiusString = Self.temperatureFormatter.string(from: roundedC)
        let fahrenheitString = Self.temperatureFormatter.string(from: roundedF)

        return .init(
            condition: condition,
            iconName: iconName,
            temperatureCelsius: celsiusString,
            temperatureFahrenheit: fahrenheitString
        )
    }

    private func iconName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: "sun.max.fill"
        case .mostlyClear, .mostlyCloudy, .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .foggy: "cloud.fog.fill"
        case .haze: "sun.haze.fill"
        case .drizzle, .rain: "cloud.rain.fill"
        case .thunderstorms: "cloud.bolt.fill"
        case .freezingRain, .hail, .sleet, .snow: "snow"
        case .blizzard, .blowingSnow: "wind.snow"
        case .blowingDust: "sun.dust.fill"
        case .breezy, .windy: "wind"
        case .hot: "sun.max.fill"
        case .flurries, .sunFlurries: "cloud.snow.fill"
        case .frigid: "thermometer.snowflake"
        case .heavyRain: "cloud.heavyrain.fill"
        case .hurricane, .tropicalStorm: "hurricane"
        case .isolatedThunderstorms, .scatteredThunderstorms:
            "cloud.sun.bolt.fill"
        case .smoky: "smoke.fill"
        default: "cloud"
        }
    }
}
