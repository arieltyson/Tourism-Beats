import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Prepares a library photo for a card.
enum FlightPhotoProcessor {
    /// Downsamples the photo to card size and re-encodes it as JPEG.
    ///
    /// Re-encoding keeps only the pixels, so location and other metadata in
    /// the original never reach the shared container the widget reads.
    @concurrent
    static func prepare(_ data: Data) async throws -> FlightPhoto {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: FlightCountdownTokens.photoPixelSize,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { throw FlightPhotoError.unreadable }
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw FlightPhotoError.unreadable }
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: FlightCountdownTokens.photoCompressionQuality,
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FlightPhotoError.unreadable }
        return FlightPhoto(data: encoded as Data, image: image)
    }
}
