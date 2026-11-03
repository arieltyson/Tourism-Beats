import CoreGraphics
import WidgetKit

struct FlightCountdownEntry: TimelineEntry, Sendable {
    let date: Date
    let flight: CountdownFlight?
    /// The flight's card photo, sized for this widget.
    var photo: CGImage?
    var isUnavailable = false
}
