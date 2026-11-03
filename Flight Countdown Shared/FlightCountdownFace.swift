import SwiftUI

struct FlightCountdownFace: View {
    let flight: CountdownFlight
    let date: Date
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: FlightCountdownStyle.spacing) {
            Label("Next Flight", systemImage: "airplane.departure")
                .font(.caption)
            Text(FlightCountdownText.remaining(until: flight.departure, from: date))
                .font(compact ? .title2 : .largeTitle)
                .bold()
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            Text(flight.route)
                .font(.headline)
            Text(flight.flightNumber)
                .font(.subheadline)
                .lineLimit(1)
            if !compact {
                Text(flight.departureLabel)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(flight.flightNumber), from \(flight.origin) to \(flight.destination), departs in \(FlightCountdownText.remaining(until: flight.departure, from: date, abbreviated: false)). Scheduled departure \(flight.departureLabel)")
    }
}
