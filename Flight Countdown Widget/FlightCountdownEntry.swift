import WidgetKit

struct FlightCountdownEntry: TimelineEntry, Sendable {
    let date: Date
    /// The upcoming flight shown, and where it falls among the others.
    let page: FlightWidgetPage?
    /// The flight's card photos, sized for this widget.
    var photos: [FlightCardImage] = []
    var isUnavailable = false
}

extension FlightCountdownEntry {
    var flight: CountdownFlight? { page?.flight }
}
