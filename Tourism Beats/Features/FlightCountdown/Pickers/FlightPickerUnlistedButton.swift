import SwiftUI

/// Uses a code that isn't in the directory, exactly as typed.
struct FlightPickerUnlistedButton: View {
    let code: String
    let action: () -> Void

    var body: some View {
        Button("Use “\(code)”", systemImage: "plus.circle", action: action)
    }
}
