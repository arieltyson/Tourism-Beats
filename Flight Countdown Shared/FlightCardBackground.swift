import SwiftUI

/// A card's backdrop: a soft mesh of its theme's tones, or the chosen photo
/// beneath a scrim that keeps the text legible.
struct FlightCardBackground: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let theme: FlightCardTheme
    var photo: CGImage?

    var body: some View {
        if theme == .photo, let photo {
            Color.clear
                .overlay {
                    Image(decorative: photo, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: contrast == .increased ? FlightCountdownStyle.strongScrim : FlightCountdownStyle.scrim,
                        startPoint: .top, endPoint: .bottom
                    )
                }
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
