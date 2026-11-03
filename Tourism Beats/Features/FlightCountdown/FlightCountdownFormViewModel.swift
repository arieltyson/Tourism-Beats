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
    var timeZoneQuery = ""
    private let initialFlight: CountdownFlight
    private let id: UUID
    let isEditing: Bool

    init(flight: CountdownFlight? = nil) {
        let initial = flight ?? CountdownFlight(
            flightNumber: "", origin: "", destination: "",
            departure: Date.now.addingTimeInterval(FlightCountdownConfiguration.secondsPerDay),
            timeZoneIdentifier: TimeZone.current.identifier
        )
        initialFlight = initial
        id = initial.id
        isEditing = flight != nil
        flightNumber = initial.flightNumber
        origin = initial.origin
        destination = initial.destination
        departure = initial.departure
        timeZoneIdentifier = initial.timeZoneIdentifier
    }

    var hasChanges: Bool { flight != initialFlight }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
    var timeZoneLabel: String { Self.label(for: timeZoneIdentifier) }

    var matchingTimeZones: [String] {
        TimeZone.knownTimeZoneIdentifiers.filter {
            timeZoneQuery.isEmpty || Self.label(for: $0).localizedStandardContains(timeZoneQuery)
                || $0.localizedStandardContains(timeZoneQuery)
        }
    }

    var canSave: Bool {
        !flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.isAirportCode(origin) && Self.isAirportCode(destination)
            && origin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                != destination.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            && TimeZone(identifier: timeZoneIdentifier) != nil
    }

    var flight: CountdownFlight {
        CountdownFlight(
            id: id,
            flightNumber: flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            origin: origin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            departure: departure,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    static func label(for identifier: String) -> String {
        identifier.replacing("_", with: " ")
    }

    private static func isAirportCode(_ value: String) -> Bool {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return code.utf8.count == 3 && code.utf8.allSatisfy { (65...90).contains($0) }
    }
}
