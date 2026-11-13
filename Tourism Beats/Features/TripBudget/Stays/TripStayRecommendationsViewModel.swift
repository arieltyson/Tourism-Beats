import Foundation
import Observation

// MARK: - TripStayRecommendationsViewModel

/// Recommends a few hotels for a trip that has none, of the kind its budget
/// affords each night, for the traveller to pick one or none.
@MainActor
@Observable
final class TripStayRecommendationsViewModel {
    /// How many hotels are recommended: enough to choose from, few enough to
    /// take in at a glance.
    static let recommendationCount = 3

    enum State: Equatable {
        case loading
        case loaded([TripStay])
        /// Nothing to recommend; the section stays out of the way.
        case unavailable
    }

    private(set) var state: State = .loading
    private(set) var selectedStayID: String?

    /// The kind of hotel searched for, when the trip has a budget.
    let hotelClass: HotelClass?
    /// What the budget leaves for each night's stay, when there is one.
    let nightlyBudget: Double?
    let currencyCode: String?
    let cityName: String

    @ObservationIgnored private let area: TripStaySearchArea
    @ObservationIgnored private let service: any TripStaySearching

    init(
        trip: Trip,
        city: CityModel,
        service: any TripStaySearching = TripStaySearchService(),
        estimator: TravelCostEstimator = TravelCostEstimator()
    ) {
        let budget = trip.budget
        self.hotelClass = budget.map {
            estimator.hotelClass(for: $0, length: trip.length, countryCode: city.country.code)
        }
        self.nightlyBudget = budget?.amount(for: .stay, per: trip.length)
        self.currencyCode = budget?.currencyCode
        self.cityName = city.name
        self.area = TripStaySearchArea(
            cityName: city.name,
            countryName: city.country.name,
            center: city.coordinate
        )
        self.service = service
    }

    // MARK: Selection

    var selectedStay: TripStay? {
        guard case let .loaded(stays) = self.state else { return nil }
        return stays.first { $0.id == self.selectedStayID }
    }

    func isSelected(_ stay: TripStay) -> Bool {
        self.selectedStayID == stay.id
    }

    /// Picks the hotel, or puts it back if it was already picked.
    func toggle(_ stay: TripStay) {
        self.selectedStayID = self.isSelected(stay) ? nil : stay.id
    }

    // MARK: Loading

    /// Searches for hotels of the budget's class, widening to any hotel where
    /// the city has none of that kind.
    func load() async {
        self.state = .loading
        var stays = await self.stays(matching: self.hotelClass?.searchQuery ?? "")
        if stays.isEmpty, self.hotelClass != nil {
            stays = await self.stays(matching: "")
        }
        guard !Task.isCancelled else { return }
        self.state = stays.isEmpty ? .unavailable : .loaded(Array(stays.prefix(Self.recommendationCount)))
    }

    private func stays(matching query: String) async -> [TripStay] {
        (try? await self.service.stays(matching: query, in: self.area)) ?? []
    }
}
