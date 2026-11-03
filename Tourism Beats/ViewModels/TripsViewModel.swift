import SwiftUI

// MARK: - TripsViewModel

/// Manages filtering, grouping, and sheet state for the Trips tab.
@MainActor
@Observable
final class TripsViewModel {
    // MARK: - UI State

    var searchText: String = ""
    var selectedStatusFilter: TripStatus?
    var isAddTripSheetPresented: Bool = false

    private let catalog: TripCatalog

    /// Uses the bundled catalog, which is built once and shared.
    convenience init() {
        self.init(catalog: .bundled)
    }

    convenience init(catalogCities: [CityModel], countries: [CountryModel]) {
        self.init(catalog: TripCatalog(cities: catalogCities, countries: countries))
    }

    init(catalog: TripCatalog) {
        self.catalog = catalog
    }

    // MARK: - Grouping

    /// A section of trips sharing the same status.
    struct TripSection: Identifiable {
        let status: TripStatus
        let trips: [Trip]
        var id: String { self.status.rawValue }
    }

    /// Groups trips by status, filters by search and status filter.
    ///
    /// Sections appear in priority order: in-progress → upcoming → completed.
    /// Trips within each section sort by start date (soonest first).
    func filteredSections(from trips: [Trip]) -> [TripSection] {
        let filtered = self.presentedTrips(from: trips).filter { trip in
            self.matchesStatusFilter(trip) && self.matchesSearch(trip)
        }

        let grouped = Dictionary(grouping: filtered, by: \.status)

        return TripStatus.allCases
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { status in
                guard let trips = grouped[status], !trips.isEmpty else {
                    return nil
                }
                let sorted = trips.sorted { lhs, rhs in
                    (lhs.startDate ?? .distantFuture)
                        < (rhs.startDate ?? .distantFuture)
                }
                return TripSection(status: status, trips: sorted)
            }
    }

    func presentedTrips(from trips: [Trip]) -> [Trip] {
        let userTrips = trips.filter { !$0.isSample }
        return userTrips.isEmpty ? trips : userTrips
    }

    func cityModel(for trip: Trip) -> CityModel? {
        self.cityModel(named: trip.city, in: trip.country)
    }

    /// The catalog city with this name in this country, if the app knows it.
    func cityModel(named cityName: String, in countryName: String) -> CityModel? {
        self.catalog.city(named: cityName, in: countryName)
    }

    func countryFlag(for trip: Trip) -> String {
        if let city = self.cityModel(for: trip) {
            return city.country.flag
        }
        return self.catalog.flag(forCountryNamed: trip.country) ?? "🧳"
    }

    // MARK: - Private

    private func matchesStatusFilter(_ trip: Trip) -> Bool {
        guard let filter = self.selectedStatusFilter else { return true }
        return trip.status == filter
    }

    private func matchesSearch(_ trip: Trip) -> Bool {
        guard !self.searchText.isEmpty else { return true }
        let query = self.searchText
        return trip.name.localizedStandardContains(query)
            || trip.city.localizedStandardContains(query)
            || trip.country.localizedStandardContains(query)
    }
}
