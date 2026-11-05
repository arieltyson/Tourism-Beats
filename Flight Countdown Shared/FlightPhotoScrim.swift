import SwiftUI

/// Shades a photo, in its own deepened colour, exactly as much as each line
/// of text needs to stay legible, and more so with Increase Contrast.
struct FlightPhotoScrim: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let photo: FlightCardImage

    var body: some View {
        let tone = FlightPhotoTone.cached(for: photo.id, image: photo.image)
        let shade = Color(.sRGB, red: tone.shade.red, green: tone.shade.green, blue: tone.shade.blue)
        // Widgets draw once, so the frame's size is read during layout.
        GeometryReader { proxy in
            let stops = FlightPhotoScrimPlan.stops(
                for: tone,
                imageSize: photo.size,
                framing: photo.framing,
                frameSize: proxy.size,
                target: contrast == .increased
                    ? FlightCountdownStyle.increasedTextContrast : FlightCountdownStyle.textContrast
            )
            LinearGradient(
                stops: stops.map { .init(color: shade.opacity($0.opacity), location: $0.location) },
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}
