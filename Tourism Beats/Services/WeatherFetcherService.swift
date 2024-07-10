//
//  WeatherFetcherService.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 10/7/24.
//

import Foundation
import WeatherKit
import CoreLocation

class WeatherFetcherService {
    private let weatherFetcherService = WeatherService()
    
    func fetchWeather(for cityName: String, completion: @escaping (Weather?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(cityName) { placemarks, error in
            guard let location = placemarks?.first?.location else {
                completion(nil)
                return
            }
            
            Task {
                do {
                    let weather = try await self.weatherFetcherService.weather(for: location)
                    completion(weather)
                } catch {
                    print("Failed to fetch weather: \(error)")
                    completion(nil)
                }
            }
        }
    }
}
