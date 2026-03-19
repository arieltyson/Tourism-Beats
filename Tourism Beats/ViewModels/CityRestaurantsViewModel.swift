import Observation
import SwiftUI

@MainActor
@Observable
final class CityRestaurantsViewModel {
    private(set) var restaurants: [CityRestaurant] = []
    private(set) var isLoading = false
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
        self.restaurants = Array(fetchedRestaurants.prefix(6))
        self.statusMessage = self.restaurants.isEmpty
            ? "No restaurant guide is available for \(self.city.name) right now."
            : nil
        self.isLoading = false
        self.hasLoaded = true
    }
}
