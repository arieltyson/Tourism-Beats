import SwiftUI

/// The swatch that opens the photo library to choose up to four photos.
struct FlightPhotoSwatchLabel: View {
    let isPreparing: Bool
    let hasPhotos: Bool

    @ScaledMetric private var size = FlightCountdownTokens.swatchSize

    var body: some View {
        Group {
            if isPreparing {
                ProgressView()
            } else {
                Label(hasPhotos ? "Change Photos" : "Choose Photos", systemImage: "photo.badge.plus")
                    .labelStyle(.iconOnly)
            }
        }
        .frame(width: size, height: size)
        .background(.fill.secondary, in: .circle)
        .padding(FlightCountdownTokens.swatchRingInset)
    }
}
