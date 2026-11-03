import SwiftUI

/// A card photo filling its frame as it was framed.
struct FlightFramedPhoto: View {
    let photo: FlightCardImage

    var body: some View {
        FlightPhotoFrameLayout(imageSize: photo.size, framing: photo.framing) {
            Image(decorative: photo.image, scale: 1)
                .resizable()
        }
        .clipped()
    }
}
