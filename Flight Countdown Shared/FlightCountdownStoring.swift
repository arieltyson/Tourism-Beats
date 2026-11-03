import Foundation

protocol FlightCountdownStoring: Sendable {
    func load() async throws -> [CountdownFlight]
    func save(_ flights: [CountdownFlight]) async throws
}
