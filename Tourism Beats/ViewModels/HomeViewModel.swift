import Foundation

// MARK: - HomeViewModel

@MainActor @Observable
final class HomeViewModel {
    private(set) var featuredCities: [CityModel] = []
    private(set) var allCityCount: Int = 0
    private(set) var isLoaded = false

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    func loadCities() {
        guard !self.isLoaded else { return }
        guard let cities = try? DataService().loadCities() else { return }
        self.allCityCount = cities.count
        let featuredPool = cities.filter(\.isEligibleForFeaturedHeroCarousel)
        let source = featuredPool.count >= 6 ? featuredPool : cities
        self.featuredCities = Array(source.shuffled().prefix(6))
        self.isLoaded = true
    }

    func localTime(for city: CityModel) -> String {
        self.timeFormatter.timeZone = city.timeZone
        return self.timeFormatter.string(from: Date())
    }
}
