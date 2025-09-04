import CoreLocation
import Foundation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherInfo: WeatherDisplayInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetcher = WeatherFetcherService()

    init(coordinate: CLLocationCoordinate2D) {
        self.loadWeather(at: coordinate)
    }

    func loadWeather(at coordinate: CLLocationCoordinate2D) {
        self.isLoading = true
        self.errorMessage = nil
        self.weatherInfo = nil

        Task {
            do {
                let displayInfo = try await fetcher.fetchWeather(at: coordinate)
                self.weatherInfo = displayInfo
            } catch {
                self.errorMessage = "Weather unavailable."
            }
            self.isLoading = false
        }
    }
}
