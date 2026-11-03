import SwiftUI

/// Darkens a photo where the card's text sits, more so with Increase Contrast.
struct FlightPhotoScrim: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        LinearGradient(
            stops: contrast == .increased ? FlightCountdownStyle.strongScrim : FlightCountdownStyle.scrim,
            startPoint: .top, endPoint: .bottom
        )
    }
}
