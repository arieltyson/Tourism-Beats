import SwiftUI

/// A card's backdrop: a soft mesh of its theme's tones, or the chosen photos
/// beneath a scrim that keeps the text legible.
struct FlightCardBackground: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let theme: FlightCardTheme
    var photos: [FlightCardImage] = []

    var body: some View {
        if theme == .photo, !photos.isEmpty {
            FlightPhotoCollage(count: photos.count) { index in
                FlightFramedPhoto(photo: photos[index])
            }
            .saturation(FlightCountdownStyle.photoSaturation)
            .contrast(FlightCountdownStyle.photoContrast)
            // The hairlines between photos stay dark in either appearance.
            .background(.black)
            .overlay { FlightPhotoScrim() }
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
