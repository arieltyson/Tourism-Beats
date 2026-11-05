import SwiftUI

/// A flight row's second line: the flight and when it leaves, at the
/// departure airport, with the time zone set aside in parentheses and two
/// text styles smaller, as on the card.
struct FlightCountdownRowSubtitle: View {
    let flight: CountdownFlight
    let now: Date

    var body: some View {
        let day = flight.formattedDeparture(Date.FormatStyle(date: .abbreviated, time: .shortened))
        let offset = Text(flight.departureOffsetNote).font(FlightCountdownTokens.rowOffsetFont)
        if flight.departure > now {
            Text("\(flight.spokenName) · \(day) \(offset)")
        } else {
            Text("Departed \(day) \(offset)")
        }
    }
}
