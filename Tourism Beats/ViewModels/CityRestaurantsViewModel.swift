import Observation
import SwiftUI

@MainActor
@Observable
final class CityRestaurantsViewModel {
    private(set) var restaurants: [CityRestaurant] = []
    /// Loading from the start, so the page's first frame shows placeholders
    /// rather than saying there's nothing to show.
    private(set) var isLoading = true
    private(set) var statusMessage: String?

    @ObservationIgnored private let city: CityModel
    @ObservationIgnored private let service: CityRestaurantProviding
    @ObservationIgnored private var hasLoaded = false

    init(
        city: CityModel,
        service: CityRestaurantProviding = CityRestaurantService.shared
    ) {
        self.city = city
        self.service = service
    }

    func loadIfNeeded() async {
        guard !self.hasLoaded else { return }
        await self.load()
    }

    func refresh() async {
        await self.load()
    }

    private func load() async {
        self.isLoading = true
        let fetchedRestaurants = await self.service.restaurants(for: self.city)
        // Every ranked result is kept; the page shows as many as fit the screen.
        self.restaurants = fetchedRestaurants
        self.statusMessage = self.restaurants.isEmpty
            ? "No restaurant guide is available for \(self.city.name) right now."
            : nil
        self.isLoading = false
        self.hasLoaded = true
    }
}
