import AppIntents
import SwiftUI
import WidgetKit

struct FlightCountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlightCountdownEntry

    var body: some View {
        Group {
            if let page = entry.page {
                FlightCountdownFace(flight: page.flight, date: entry.date, style: family == .systemSmall ? .small : .medium) {
                    if page.hasOthers { FlightPageIndicator(page: page) }
                }
                // The face reads as one element, so VoiceOver moves on with an action.
                .accessibilityValue(page.hasOthers ? Text("Flight \(page.position) of \(page.count)") : Text(""))
                .accessibilityAction(named: "Next Flight", intent: ShowNextFlightIntent())
                // Moving to another flight slides it in, like turning a page.
                .id(page.flight.id)
                .transition(.push(from: .trailing))
            } else {
                VStack(alignment: .leading, spacing: FlightCountdownStyle.spacing) {
                    FlightPathGlyph(progress: FlightPathGlyphTokens.restingProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    Text(entry.isUnavailable ? "Open to Update" : "Your Next Takeoff")
                        .font(.headline)
                    Text(entry.isUnavailable ? "Open Tourism Beats to load your flights." : "Add a flight in Tourism Beats.")
                        .font(.subheadline)
                        .opacity(FlightCountdownStyle.secondaryOpacity)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) {
            FlightCardBackground(theme: entry.flight?.cardTheme ?? .twilight, photos: entry.photos)
        }
        .widgetURL(FlightCountdownConfiguration.deepLink)
    }
}
