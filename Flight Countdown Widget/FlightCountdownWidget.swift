import SwiftUI
import WidgetKit

@main
struct FlightCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FlightCountdownConfiguration.widgetKind, provider: FlightCountdownProvider()) { entry in
            FlightCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Flight Countdown")
        .description("Count down to your next scheduled flight, with any airline.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
