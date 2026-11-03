import CoreLocation
import Foundation

@MainActor
@Observable
final class WeatherViewModel {
    private(set) var weatherInfo: WeatherDisplayInfo?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    @ObservationIgnored private let coordinate: CLLocationCoordinate2D
    @ObservationIgnored private let fetcher = WeatherFetcherService()

    /// Creating the model does no work; the view loads it when it appears,
    /// so rebuilding the view never starts another request.
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    /// Loads the weather once; later calls keep what's already shown.
    func load() async {
        guard self.weatherInfo == nil else { return }
        self.isLoading = true
        self.errorMessage = nil
        do {
            self.weatherInfo = try await self.fetcher.fetchWeather(at: self.coordinate)
        } catch is CancellationError {
            // The page went away mid-load; the next appearance tries again.
        } catch {
            self.errorMessage = "Weather unavailable."
        }
        self.isLoading = false
    }
}
