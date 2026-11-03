import SwiftUI
import WidgetKit

struct FlightCountdownWidgetView: View {
    let entry: FlightCountdownEntry

    var body: some View {
        Group {
            if let flight = entry.flight {
                FlightCountdownFace(flight: flight, date: entry.date, compact: true)
            } else {
                VStack(alignment: .leading, spacing: FlightCountdownStyle.spacing) {
                    Image(systemName: "airplane.departure")
                        .font(.title2)
                        .accessibilityHidden(true)
                    Text(entry.isUnavailable ? "Open to Update" : "Your Next Takeoff")
                        .font(.headline)
                    Text(entry.isUnavailable ? "Open Tourism Beats to load your flights." : "Add a flight in Tourism Beats.")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }
        }
        .containerBackground(for: .widget) { FlightCountdownBackdrop() }
        .widgetURL(FlightCountdownConfiguration.deepLink)
    }
}
