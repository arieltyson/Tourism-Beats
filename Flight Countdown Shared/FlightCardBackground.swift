import SwiftUI

/// A card's backdrop: a soft mesh of its theme's tones, or a photo filling
/// it beneath a scrim that keeps the text legible.
struct FlightCardBackground: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let theme: FlightCardTheme
    var photo: FlightCardImage?

    var body: some View {
        if theme == .photo, let photo {
            FlightFramedPhoto(photo: photo)
                .saturation(FlightCountdownStyle.photoSaturation)
                .contrast(FlightCountdownStyle.photoContrast)
                .overlay { FlightPhotoScrim(photo: photo) }
        } else if contrast == .increased {
            theme.palette[0]
        } else {
            let tones = theme.palette
            MeshGradient(
                width: 3, height: 3, points: FlightCountdownStyle.meshPoints,
                colors: [tones[0], tones[0], tones[1], tones[0], tones[1], tones[2], tones[1], tones[2], tones[2]]
            )
        }
    }
}
