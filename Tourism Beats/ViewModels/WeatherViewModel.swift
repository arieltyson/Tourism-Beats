//
//  WeatherViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 10/7/24.
//

import Foundation
import WeatherKit

class WeatherViewModel: ObservableObject {
    @Published var weatherCondition: String = ""
    @Published var weatherIconName: String = ""
    @Published var temperature: String = ""
    
    private var weatherFetcherService = WeatherFetcherService()
    
    init(cityName: String) {
        fetchWeather(for: cityName)
    }
    
    private func fetchWeather(for cityName: String) {
        weatherFetcherService.fetchWeather(for: cityName) { [weak self] weather in
            guard let self = self, let weather = weather else { return }
            DispatchQueue.main.async {
                self.weatherCondition = weather.currentWeather.condition.description
                self.weatherIconName = self.getWeatherIconName(for: weather.currentWeather.condition)
                let roundedTemperature = Int(weather.currentWeather.temperature.value.rounded())
                self.temperature = "\(roundedTemperature) \(weather.currentWeather.temperature.unit.symbol)"
            }
        }
    }
    
    private func getWeatherIconName(for condition: WeatherCondition) -> String {
            switch condition {
            case .clear:
                return "sun.max.fill"
            case .mostlyClear, .partlyCloudy, .mostlyCloudy:
                return "cloud.sun.fill"
            case .cloudy:
                return "cloud.fill"
            case .foggy:
                return "cloud.fog.fill"
            case .haze:
                return "sun.haze.fill"
            case .drizzle, .rain:
                return "cloud.rain.fill"
            case .thunderstorms:
                return "cloud.bolt.fill"
            case .snow, .sleet, .freezingRain, .hail:
                return "snow"
            case .blizzard:
                return "wind.snow"
            default:
                return "questionmark"
            }
    }
}

