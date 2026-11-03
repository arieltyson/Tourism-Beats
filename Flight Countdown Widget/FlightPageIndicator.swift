import AppIntents
import SwiftUI

/// Shows which of the upcoming flights is on the widget; tapping it moves
/// on to the next. Long lists show their position as a number instead.
struct FlightPageIndicator: View {
    let page: FlightWidgetPage

    @ScaledMetric(relativeTo: .caption) private var dotSize = FlightCountdownStyle.pageDotSize

    var body: some View {
        Button(intent: ShowNextFlightIntent()) {
            Group {
                if page.count > FlightCountdownStyle.maximumPageDots {
                    Text("\(page.position)/\(page.count)")
                        .font(.caption.monospacedDigit())
                        .bold()
                } else {
                    HStack(spacing: FlightCountdownStyle.pageDotSpacing) {
                        ForEach(1...page.count, id: \.self) { position in
                            Circle()
                                .frame(width: dotSize, height: dotSize)
                                .opacity(position == page.position ? 1 : FlightCountdownStyle.remainingTrackOpacity)
                        }
                    }
                }
            }
            .padding(FlightCountdownStyle.pageIndicatorPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // VoiceOver reaches this through the face's Next Flight action.
    }
}
