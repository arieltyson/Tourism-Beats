import WidgetKit

struct FlightCountdownEntry: TimelineEntry, Sendable {
    let date: Date
    /// The next flight to depart at `date`.
    let flight: CountdownFlight?
    /// The flight's card photos, sized for this widget.
    var photos: [FlightCardImage] = []
    var isUnavailable = false
}
