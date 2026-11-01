import Foundation

// MARK: - TripPlanRequest

/// A just-added trip waiting for its suggested plan.
struct TripPlanRequest: Identifiable {
    let id = UUID()
    let trip: Trip
    let city: CityModel
}
