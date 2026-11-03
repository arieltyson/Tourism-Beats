import Foundation

/// A flight described as a calendar event, independent of any calendar app.
struct FlightCalendarEvent: Identifiable, Hashable, Sendable {
    /// Stable per flight, so adding the same flight again updates rather
    /// than duplicates it in calendars that honour iCalendar UIDs.
    let id: String
    /// Such as "Air Canada 308 to Montréal".
    let title: String
    let start: Date
    /// Estimated from the distance flown.
    let end: Date
    /// The departure airport's zone, so the event reads in local time there.
    let timeZone: TimeZone
    /// The departure airport by name, which calendars can map.
    let location: String
    /// The route and flight, such as "YVR → YUL · AC 308".
    let notes: String
    let url: URL?

    init(flight: CountdownFlight, airports: AirportDirectory = .bundled) {
        let origin = airports.airport(code: flight.origin)
        let destination = airports.airport(code: flight.destination)
        id = "\(flight.id.uuidString)@tourismbeats"
        title = String(localized: "\(flight.spokenName) to \(flight.destinationName)")
        start = flight.departure
        end = flight.departure.addingTimeInterval(FlightDurationEstimator.duration(from: origin, to: destination))
        timeZone = flight.timeZone
        location = origin?.name ?? flight.origin
        notes = "\(flight.route) · \(flight.designator)"
        url = FlightCountdownConfiguration.deepLink
    }

    /// The file name an exported event is shared under, such as "AC 308.ics".
    var fileName: String { "\(title.replacing("/", with: "-")).ics" }
}
