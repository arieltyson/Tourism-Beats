import SwiftUI

struct FlightCountdownBackdrop: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        LinearGradient(
            colors: contrast == .increased
                ? [FlightCountdownStyle.night, FlightCountdownStyle.night]
                : [FlightCountdownStyle.night, FlightCountdownStyle.horizon],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
