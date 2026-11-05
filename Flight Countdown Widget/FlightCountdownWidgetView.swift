import SwiftUI
import WidgetKit

struct FlightCountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlightCountdownEntry

    var body: some View {
        Group {
            if let flight = entry.flight {
                FlightCountdownFace(flight: flight, date: entry.date, style: family == .systemSmall ? .small : .medium)
                    // When a flight departs, the next slides in, like turning a page.
                    .id(flight.id)
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
            FlightCardBackground(
                theme: entry.flight?.cardTheme ?? .twilight,
                photo: entry.flight.flatMap { FlightPhotoRotation.photo(from: entry.photos, of: $0, at: entry.date) }
            )
        }
        .widgetURL(FlightCountdownConfiguration.deepLink)
    }
}
