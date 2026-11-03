/// How much a countdown face shows for the space it has.
enum FlightCountdownFaceStyle: Sendable {
    /// The small widget: destination, date, countdown, and track.
    case small
    /// The medium widget adds the flight number and departure time.
    case medium
    /// The in-app card adds the airport codes under the track.
    case card

    var showsFlightNumber: Bool { self != .small }
    var showsTime: Bool { self != .small }
    var showsAirports: Bool { self == .card }
}
