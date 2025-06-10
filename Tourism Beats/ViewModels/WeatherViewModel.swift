import CoreLocation
import Foundation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherInfo: WeatherDisplayInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetcher = WeatherFetcherService()

    init(coordinate: CLLocationCoordinate2D) {
        loadWeather(at: coordinate)
    }

    func loadWeather(at coordinate: CLLocationCoordinate2D) {
        isLoading = true
        errorMessage = nil
        weatherInfo = nil

        Task {
            do {
                let displayInfo = try await fetcher.fetchWeather(at: coordinate)
                weatherInfo = displayInfo
            } catch {
                errorMessage = "Weather unavailable."
            }
            isLoading = false
        }
    }
}
