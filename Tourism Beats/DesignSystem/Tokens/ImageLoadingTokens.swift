import Foundation

/// How remote and stored images are fetched, decoded, and kept, so every
/// image in the app loads the same way.
enum ImageLoadingTokens {
    /// Decoded images kept in memory, so a card that scrolls back draws at once.
    static let memoryCostLimit = 150 * 1_024 * 1_024
    /// A load shorter than this shows no spinner; most cached images arrive well within it.
    static let spinnerDelay: Duration = .milliseconds(350)
    /// Decoded sizes are rounded up to this many pixels, so small layout
    /// changes reuse the image already decoded.
    static let pixelSizeStep = 256
    /// A filled frame can crop an image of another shape, which needs more
    /// pixels than the frame's longer side; this covers the usual photos.
    static let fillAllowance: CGFloat = 2
    /// Nothing on an iPhone screen needs a larger decode.
    static let maximumPixelSize = 2_560
    /// How wide a Wikimedia image is requested for cards and heroes. Wikimedia
    /// pre-renders and caches this standard width at its edge.
    static let wikimediaDisplayWidth = 1_280
}
