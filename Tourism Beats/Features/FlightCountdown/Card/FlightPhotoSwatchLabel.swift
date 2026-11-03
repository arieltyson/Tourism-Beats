import SwiftUI

/// The swatch that opens the photo library.
struct FlightPhotoSwatchLabel: View {
    let isPreparing: Bool
    let hasPhoto: Bool

    @ScaledMetric private var size = FlightCountdownTokens.swatchSize

    var body: some View {
        Group {
            if isPreparing {
                ProgressView()
            } else {
                Label(hasPhoto ? "Choose Another Photo" : "Choose Photo", systemImage: "photo.badge.plus")
                    .labelStyle(.iconOnly)
            }
        }
        .frame(width: size, height: size)
        .background(.fill.secondary, in: .circle)
        .padding(FlightCountdownTokens.swatchRingInset)
    }
}
