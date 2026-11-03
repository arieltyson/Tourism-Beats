import CoreGraphics
import Foundation

/// Decoded images by URL, evicted by the system under memory pressure.
///
/// `NSCache` is safe to use from any thread, which lets views read it
/// synchronously and draw a cached image on their first frame.
final class ImageMemoryCache: @unchecked Sendable {
    private final class Entry {
        let image: CGImage
        /// Decoded at the source's full size, so no larger decode exists.
        let isFullSize: Bool

        init(image: CGImage, isFullSize: Bool) {
            self.image = image
            self.isFullSize = isFullSize
        }

        var longestSide: Int { max(image.width, image.height) }

        func satisfies(_ pixelSize: Int) -> Bool { isFullSize || longestSide >= pixelSize }
    }

    private let cache = NSCache<NSURL, Entry>()

    init(costLimit: Int = ImageLoadingTokens.memoryCostLimit) {
        cache.totalCostLimit = costLimit
    }

    /// The image for `url` if one at least `pixelSize` along its longer side,
    /// or the full image, is in memory. Zero accepts any size.
    func image(for url: URL, pixelSize: Int = 0) -> CGImage? {
        guard let entry = cache.object(forKey: url as NSURL), entry.satisfies(pixelSize) else { return nil }
        return entry.image
    }

    /// Keeps the larger of the image already held and `image`.
    func insert(_ image: CGImage, for url: URL, requestedPixelSize: Int) {
        let entry = Entry(image: image, isFullSize: max(image.width, image.height) < requestedPixelSize)
        if let existing = cache.object(forKey: url as NSURL),
           existing.isFullSize || existing.longestSide >= entry.longestSide {
            return
        }
        cache.setObject(entry, forKey: url as NSURL, cost: image.bytesPerRow * image.height)
    }
}
