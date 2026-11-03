import SwiftUI

/// The countdown card's content: where the flight is going, when, how long
/// is left, and how far along the wait is.
struct FlightCountdownFace: View {
    let flight: CountdownFlight
    let date: Date
    var style: FlightCountdownFaceStyle = .card

    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize = FlightCountdownStyle.countdownSize
    @ScaledMetric(relativeTo: .largeTitle) private var compactCountdownSize = FlightCountdownStyle.compactCountdownSize

    var body: some View {
        VStack(alignment: .leading, spacing: FlightCountdownStyle.spacing) {
            HStack(alignment: .firstTextBaseline, spacing: FlightCountdownStyle.spacing) {
                VStack(alignment: .leading) {
                    Text(flight.destinationName.isEmpty ? String(localized: "Destination") : flight.destinationName)
                        .font(.headline)
                    Text(departureDay)
                        .font(.subheadline)
                        .opacity(FlightCountdownStyle.secondaryOpacity)
                }
                .lineLimit(1)
                Spacer(minLength: FlightCountdownStyle.spacing)
                if style.showsFlightNumber, !flight.flightNumber.isEmpty {
                    Text(flight.designator)
                        .font(.caption.monospacedDigit())
                        .bold()
                        .opacity(FlightCountdownStyle.secondaryOpacity)
                }
            }
            Spacer(minLength: 0)
            FlightCountdownClock(
                components: FlightCountdownText.components(until: flight.departure, from: date, calendar: calendar),
                calendar: calendar,
                numberSize: style == .card ? countdownSize : compactCountdownSize
            )
            FlightProgressTrack(progress: flight.countdownProgress(at: date))
            if style.showsAirports {
                HStack {
                    Text(flight.origin)
                    Spacer(minLength: FlightCountdownStyle.spacing)
                    Text(flight.destination)
                }
                .font(.caption.monospaced())
                .bold()
                .opacity(FlightCountdownStyle.secondaryOpacity)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// The departure on the airport's own calendar, such as "Sun, Dec 20".
    private var departureDay: String {
        var format = style.showsTime
            ? Date.FormatStyle.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()
            : Date.FormatStyle.dateTime.month(.abbreviated).day()
        format.timeZone = flight.timeZone
        return flight.departure.formatted(format)
    }

    /// Months and days are counted on the departure airport's calendar, the
    /// same one the date above is shown in.
    private var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = flight.timeZone
        return calendar
    }

    private var accessibilityDescription: String {
        let remaining = FlightCountdownText.remaining(until: flight.departure, from: date, calendar: calendar)
        return String(localized: """
            \(flight.spokenName), from \(flight.originName) to \(flight.destinationName), departs in \(remaining). \
            Scheduled departure \(flight.departureLabel)
            """)
    }
}
