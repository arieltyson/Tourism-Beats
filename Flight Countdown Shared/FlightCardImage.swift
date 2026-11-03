import CoreGraphics
import Foundation

/// A card photo ready to draw.
struct FlightCardImage: Identifiable, Sendable {
    let id: UUID
    let image: CGImage
    var framing: FlightPhotoFraming

    var size: CGSize { CGSize(width: image.width, height: image.height) }

    /// The flight's photos that have loaded, in the card's order.
    static func images(for flight: CountdownFlight, from images: [UUID: CGImage]) -> [Self] {
        guard flight.cardTheme == .photo else { return [] }
        return flight.photos.compactMap { photo in
            images[photo.id].map { Self(id: photo.id, image: $0, framing: photo.framing) }
        }
    }
}
