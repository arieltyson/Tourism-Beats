import SwiftUI

/// The time left as a departures board shows it: each number set large
/// with its unit beneath, such as "01 month · 17 days".
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
            HStack(alignment: .firstTextBaseline, spacing: FlightCountdownStyle.clockSpacing) {
                ForEach(components, id: \.unit) { component in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(component.value, format: .number.precision(.integerLength(FlightCountdownStyle.clockDigits...)))
                            .font(.system(size: numberSize, weight: .bold).monospacedDigit())
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
