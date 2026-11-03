import WidgetKit

struct FlightCountdownEntry: TimelineEntry, Sendable {
    let date: Date
    let flight: CountdownFlight?
    var isUnavailable = false
}
