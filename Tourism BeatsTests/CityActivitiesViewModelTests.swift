import CoreLocation
import Testing
@testable import Tourism_Beats

// MARK: - CityActivitiesViewModelTests

@MainActor
struct CityActivitiesViewModelTests {
    @Test func loadIfNeededFetchesOnlyOnce() async {
        let service = MockCityActivityService(activities: [Self.sampleActivity])
        let viewModel = CityActivitiesViewModel(
            city: Self.sampleCity,
            service: service
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(viewModel.activities.count == 1)
        #expect(await service.requestCount() == 1)
    }

    @Test func refreshRequestsActivitiesAgain() async {
        let service = MockCityActivityService(activities: [Self.sampleActivity])
        let viewModel = CityActivitiesViewModel(
            city: Self.sampleCity,
            service: service
        )

        await viewModel.loadIfNeeded()
        await viewModel.refresh()

        #expect(await service.requestCount() == 2)
    }
}

extension CityActivitiesViewModelTests {
    private actor MockCityActivityService: CityActivityProviding {
        private let activitiesToReturn: [CityActivity]
        private var totalRequests = 0

        init(activities: [CityActivity]) {
            self.activitiesToReturn = activities
        }

        func activities(for city: CityModel) async -> [CityActivity] {
            _ = city
            self.totalRequests += 1
            return self.activitiesToReturn
        }

        func requestCount() -> Int {
            self.totalRequests
        }
    }

    private static let sampleCity = CityModel(
        id: "paris-fr",
        name: "Paris",
        country: CountryModel(name: "France", code: "FR", flag: "🇫🇷"),
        imageURL: URL(string: "https://example.com/paris.jpg")!,
        coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        timeZoneIdentifier: "Europe/Paris"
    )

    private static let sampleActivity = CityActivity(
        id: "eiffel_tower",
        name: "Eiffel Tower",
        summary: "An iconic Paris landmark.",
        category: "Landmarks",
        kind: .see,
        imageURL: nil,
        officialURL: nil,
        sourceURL: nil,
        sourceName: "Wikivoyage",
        hours: nil,
        price: nil,
        address: nil,
        directions: nil,
        timingTip: nil,
        latitude: 48.858,
        longitude: 2.2953,
        wikidataIdentifier: "Q243",
        sourcePageTitle: "Paris/7th arrondissement",
        sourceAnchor: "Q243"
    )
}
