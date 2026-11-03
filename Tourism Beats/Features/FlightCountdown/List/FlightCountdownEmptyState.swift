import SwiftUI

/// Shown before any flight is added; the Add button lives in the toolbar.
struct FlightCountdownEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("Your Next Takeoff", systemImage: "airplane.departure")
        } description: {
            Text("Count down to any flight — yours, or a loved one’s.")
        }
    }
}
