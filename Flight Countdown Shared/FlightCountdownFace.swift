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
                    // Where the full line doesn't fit, the weekday gives way
                    // before the time zone does.
                    ViewThatFits(in: .horizontal) {
                        FlightDepartureLine(flight: flight, showsTime: style.showsTime)
                        FlightDepartureLine(flight: flight, showsTime: style.showsTime, includesWeekday: false)
                    }
                    .font(FlightCountdownStyle.departureFont)
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
        .shadow(
            color: .black.opacity(flight.cardTheme == .photo ? FlightCountdownStyle.photoTextShadowOpacity : 0),
            radius: FlightCountdownStyle.photoTextShadowRadius,
            y: FlightCountdownStyle.photoTextShadowOffset
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
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
