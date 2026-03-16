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
                guard let trips = grouped[status], !trips.isEmpty else { return nil }
                let sorted = trips.sorted { lhs, rhs in
                    (lhs.startDate ?? .distantFuture) < (rhs.startDate ?? .distantFuture)
                }
                return TripSection(status: status, trips: sorted)
            }
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
