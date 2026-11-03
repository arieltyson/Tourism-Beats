import SwiftUI

/// The time left as a departures board shows it: each number set large
/// with its unit beneath, such as "01 month · 17 days", the largest unit
/// leading and the next one smaller.
struct FlightCountdownClock: View {
    let components: [FlightCountdownComponent]
    let calendar: Calendar
    let numberSize: CGFloat

    var body: some View {
        if components.isEmpty {
            Text("Departed")
                .font(.system(size: numberSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(FlightCountdownStyle.minimumCountdownScale)
        } else {
            HStack(alignment: .lastTextBaseline, spacing: FlightCountdownStyle.clockSpacing) {
                ForEach(components.enumerated(), id: \.element.unit) { index, component in
                    // The largest unit leads; the rest refine it at a smaller size.
                    let size = index == 0 ? numberSize : numberSize * FlightCountdownStyle.secondaryClockScale
                    VStack(alignment: .leading, spacing: 0) {
                        Text(component.value, format: .number.precision(.integerLength(FlightCountdownStyle.clockDigits...)))
                            .font(.system(size: size, weight: .bold).monospacedDigit())
                            .contentTransition(.numericText(value: Double(component.value)))
                        Text(component.unitLabel(calendar: calendar))
                            .font(.caption)
                            .bold()
                            .opacity(FlightCountdownStyle.secondaryOpacity)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(FlightCountdownStyle.minimumCountdownScale)
                }
            }
        }
    }
}
