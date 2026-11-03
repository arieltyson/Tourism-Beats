import SwiftUI

/// Presents the New Event sheet for whichever flight event is set, and
/// confirms a save with a haptic.
struct FlightCalendarSheet: ViewModifier {
    @Binding var event: FlightCalendarEvent?
    @State private var savedCount = 0

    func body(content: Content) -> some View {
        content
            .sheet(item: $event) { event in
                FlightEventEditor(event: event) { saved in
                    if saved { savedCount += 1 }
                    self.event = nil
                }
                .ignoresSafeArea()
            }
            .sensoryFeedback(.success, trigger: savedCount)
    }
}

extension View {
    /// Shows the system's New Event sheet whenever `event` is set.
    func flightCalendarSheet(for event: Binding<FlightCalendarEvent?>) -> some View {
        modifier(FlightCalendarSheet(event: event))
    }
}
