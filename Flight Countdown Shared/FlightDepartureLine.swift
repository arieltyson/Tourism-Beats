import SwiftUI

/// When the flight leaves, with its GMT offset set a size smaller: the
/// offset clarifies the time rather than competing with it.
struct FlightDepartureLine: View {
    let flight: CountdownFlight
    let showsTime: Bool
    var includesWeekday = true

    var body: some View {
        let day = flight.departureDay(showsTime: showsTime, includesWeekday: includesWeekday)
        if showsTime {
            Text("\(day) \(Text(flight.departureOffset).font(FlightCountdownStyle.offsetFont))")
        } else {
            Text(day)
        }
    }
}
