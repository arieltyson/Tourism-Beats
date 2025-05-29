import CoreLocation
import Foundation
import WeatherKit

@MainActor
class WeatherViewModel: ObservableObject {
    struct WeatherDisplayInfo {
        let condition: String
        let iconName: String
        let temperature: String
    }

    @Published var weatherInfo: WeatherDisplayInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetcher = WeatherFetcherService()

    /// Kick off load as soon as you have the coordinate
    init(coordinate: CLLocationCoordinate2D) {
        loadWeather(at: coordinate)
    }

    /// Public trigger in case you want to reload
    func loadWeather(at coordinate: CLLocationCoordinate2D) {
        isLoading = true
        errorMessage = nil
        weatherInfo = nil

        Task {
            do {
                let weather = try await fetcher.fetchWeather(at: coordinate)
                weatherInfo = processWeather(weather)
            } catch {
                errorMessage = "Weather unavailable."
            }
            isLoading = false
        }
    }

    private func processWeather(_ weather: Weather) -> WeatherDisplayInfo {
        let current = weather.currentWeather
        let condition = current.condition.description
        let iconName = iconName(for: current.condition)
        let temp = Int(current.temperature.value.rounded())
        let tempStr = "\(temp) \(current.temperature.unit.symbol)"
        return .init(
            condition: condition,
            iconName: iconName,
            temperature: tempStr
        )
    }

    private func iconName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .mostlyClear, .partlyCloudy,
            .mostlyCloudy:
            return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .haze: return "sun.haze.fill"
        case .drizzle, .rain: return "cloud.rain.fill"
        case .thunderstorms: return "cloud.bolt.fill"
        case .snow, .sleet, .freezingRain,
            .hail:
            return "snow"
        case .blizzard: return "wind.snow"
        case .blowingDust: return "sun.dust.fill"
        case .blowingSnow: return "wind.snow"
        case .breezy, .windy: return "wind"
        case .hot: return "sun.max.fill"
        case .flurries, .sunFlurries: return "cloud.snow.fill"
        case .frigid: return "thermometer.snowflake"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .hurricane, .tropicalStorm: return "hurricane"
        case .isolatedThunderstorms,
            .scatteredThunderstorms:
            return "cloud.sun.bolt.fill"
        case .smoky: return "smoke.fill"
        default: return "cloud"
        }
    }
}
