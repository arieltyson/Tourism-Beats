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
    var tripToEdit: Trip?

    private let catalogCitiesByLookupKey: [String: CityModel]
    private let countryFlagsByNormalizedName: [String: String]

    convenience init(dataService: DataService = DataService()) {
        let catalogCities = (try? dataService.loadCities()) ?? []
        let countries = (try? dataService.loadCountries()) ?? []
        self.init(catalogCities: catalogCities, countries: countries)
    }

    init(catalogCities: [CityModel], countries: [CountryModel]) {
        self.catalogCitiesByLookupKey = Self.makeCityLookup(from: catalogCities)
        self.countryFlagsByNormalizedName = Dictionary(
            uniqueKeysWithValues: countries.map {
                (Self.normalizedLookupValue($0.name), $0.flag)
            }
        )
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
        let filtered = trips.filter { trip in
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

    func cityModel(for trip: Trip) -> CityModel? {
        self.catalogCitiesByLookupKey[
            Self.lookupKey(cityName: trip.city, countryName: trip.country)
        ]
    }

    func countryFlag(for trip: Trip) -> String {
        if let city = self.cityModel(for: trip) {
            return city.country.flag
        }

        return self.countryFlagsByNormalizedName[
            Self.normalizedLookupValue(trip.country)
        ] ?? "🧳"
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

    private static func lookupKey(cityName: String, countryName: String)
    -> String
    {
        [
            self.normalizedLookupValue(cityName),
            self.normalizedLookupValue(countryName)
        ]
        .joined(separator: "|")
    }

    private static func normalizedLookupValue(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func makeCityLookup(from catalogCities: [CityModel])
    -> [String: CityModel]
    {
        catalogCities.reduce(into: [:]) { partialResult, city in
            let key = Self.lookupKey(
                cityName: city.name,
                countryName: city.country.name
            )

            // The city catalog can legitimately contain duplicate rows for the
            // same city/country pair. Keep the first stable match instead of
            // crashing on duplicate dictionary keys.
            if partialResult[key] == nil {
                partialResult[key] = city
            }
        }
    }
}
