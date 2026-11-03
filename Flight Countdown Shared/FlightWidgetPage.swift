/// The flight a widget shows, and where it falls among the upcoming ones.
struct FlightWidgetPage: Equatable, Sendable {
    let flight: CountdownFlight
    /// Counted from 1, in order of departure.
    let position: Int
    let count: Int

    var hasOthers: Bool { count > 1 }
}
