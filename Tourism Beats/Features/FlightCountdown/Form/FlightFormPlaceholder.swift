import SwiftUI

/// Marks a choice that hasn't been made yet.
struct FlightFormPlaceholder: View {
    var body: some View {
        Text("Choose")
            .foregroundStyle(.tertiary)
    }
}
