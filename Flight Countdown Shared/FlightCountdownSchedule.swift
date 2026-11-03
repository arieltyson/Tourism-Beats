import Foundation

enum FlightCountdownSchedule {
    static let entryInterval: TimeInterval = 5 * FlightCountdownConfiguration.secondsPerMinute
    static let horizon: TimeInterval = 6 * FlightCountdownConfiguration.secondsPerHour

    /// Departure boundaries are explicit so the next flight replaces this one.
    static func dates(for flights: [CountdownFlight], from now: Date) -> [Date] {
        let end = now.addingTimeInterval(horizon)
        let regular = stride(from: entryInterval, through: horizon, by: entryInterval)
            .map { now.addingTimeInterval($0) }
        let departures = flights.map(\.departure).filter { $0 > now && $0 <= end }
        return Set([now] + regular + departures).sorted()
    }
}
