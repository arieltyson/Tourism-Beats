import Foundation
import Observation

@MainActor
@Observable
final class FlightCountdownFormViewModel {
    var flightNumber: String
    var origin: String
    var destination: String
    var departure: Date
    var timeZoneIdentifier: String
    private let initialFlight: CountdownFlight
    private let id: UUID
    let isEditing: Bool

    init(flight: CountdownFlight? = nil) {
        let initial = flight ?? CountdownFlight(
            airlineCode: "", flightNumber: "", origin: "", destination: "",
            departure: Date.now.addingTimeInterval(FlightCountdownConfiguration.secondsPerDay),
            timeZoneIdentifier: TimeZone.current.identifier
        )
        initialFlight = initial
        id = initial.id
        isEditing = flight != nil
        flightNumber = initial.designator
        origin = initial.origin
        destination = initial.destination
        departure = initial.departure
        timeZoneIdentifier = initial.timeZoneIdentifier
    }

    var hasChanges: Bool { flight != initialFlight }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
    var timeZoneLabel: String { FlightTimeZoneOption(timeZone: timeZone, at: departure).summary }

    var canSave: Bool {
        !flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.isAirportCode(origin) && Self.isAirportCode(destination)
            && origin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                != destination.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            && TimeZone(identifier: timeZoneIdentifier) != nil
    }

    var flight: CountdownFlight {
        let designator = CountdownFlight.split(designator: flightNumber)
        return CountdownFlight(
            id: id,
            airlineCode: designator.airlineCode,
            flightNumber: designator.flightNumber,
            origin: origin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            departure: departure,
            timeZoneIdentifier: timeZoneIdentifier,
            countdownStartedAt: initialFlight.countdownStartedAt
        )
    }

    private static func isAirportCode(_ value: String) -> Bool {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return code.utf8.count == 3 && code.utf8.allSatisfy { (65...90).contains($0) }
    }
}
