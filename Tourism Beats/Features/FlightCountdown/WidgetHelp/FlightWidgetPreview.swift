import SwiftUI

/// The small widget as it will look on the Home Screen.
struct FlightWidgetPreview: View {
    let flight: CountdownFlight
    var photos: [FlightCardImage] = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: FlightCountdownConfiguration.secondsPerMinute)) { context in
            FlightCountdownFace(flight: flight, date: context.date, style: .small)
                .padding(FlightCountdownTokens.widgetPreviewPadding)
                .frame(width: FlightCountdownTokens.smallWidgetSide, height: FlightCountdownTokens.smallWidgetSide)
                .background {
                    FlightCardBackground(
                        theme: flight.cardTheme,
                        photo: FlightPhotoRotation.photo(from: photos, of: flight, at: context.date)
                    )
                }
                .clipShape(.rect(cornerRadius: FlightCountdownTokens.widgetPreviewCornerRadius))
        }
        // Widgets cap text size to fit; the preview matches what will appear.
        .dynamicTypeSize(...FlightCountdownTokens.widgetPreviewMaximumTypeSize)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Widget preview")
    }
}
