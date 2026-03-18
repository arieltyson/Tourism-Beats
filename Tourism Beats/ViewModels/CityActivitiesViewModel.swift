import Observation
import SwiftUI

@MainActor
@Observable
final class CityActivitiesViewModel {
    private(set) var activities: [CityActivity] = []
    private(set) var isLoading = false
    private(set) var statusMessage: String?

    @ObservationIgnored private let city: CityModel
    @ObservationIgnored private let service: CityActivityProviding
    @ObservationIgnored private var hasLoaded = false

    init(
        city: CityModel,
        service: CityActivityProviding = CityActivityService.shared
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
        let fetchedActivities = await self.service.activities(for: self.city)
        self.activities = Array(fetchedActivities.prefix(6))
        self.statusMessage = self.activities.isEmpty
            ? "No activity guide is available for \(self.city.name) right now."
            : nil
        self.isLoading = false
        self.hasLoaded = true
    }
}
