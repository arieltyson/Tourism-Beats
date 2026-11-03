import Foundation
@testable import Tourism_Beats

actor FailingFlightStore: FlightCountdownStoring {
    let flights: [CountdownFlight]
    init(flights: [CountdownFlight]) { self.flights = flights }
    func load() -> [CountdownFlight] { flights }
    func save(_ flights: [CountdownFlight]) throws { throw FlightCountdownStorageError.unavailable }
}
