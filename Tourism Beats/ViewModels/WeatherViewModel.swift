//
//  WeatherViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 10/7/24.
//

import Foundation
import WeatherKit

class WeatherViewModel: ObservableObject {
    @Published var weatherDescription: String = ""
    private var weatherFetcherService = WeatherFetcherService()
    
    init(cityName: String) {
        fetchWeather(for: cityName)
    }
    
    private func fetchWeather(for cityName: String) {
        weatherFetcherService.fetchWeather(for: cityName) { [weak self] weather in
            guard let self = self, let weather = weather else { return }
            DispatchQueue.main.async {
                self.weatherDescription = self.formatWeather(weather)
            }
        }
    }
    
    private func formatWeather(_ weather: Weather) -> String {
        return "Temperature: \(weather.currentWeather.temperature)°\n" +
               "Condition: \(weather.currentWeather.condition.description)"
    }
}
