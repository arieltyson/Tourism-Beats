import Foundation

/// Finds places to stay in a trip's city.
protocol TripStaySearching: Sendable {
    /// Hotels matching `query` in `area`; an empty query lists the area's hotels.
    func stays(matching query: String, in area: TripStaySearchArea) async throws -> [TripStay]
}
