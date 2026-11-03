import CoreGraphics
import Foundation
import ImageIO

/// Fetches and decodes images away from the main actor.
enum ImageDecoder {
    /// Loads the image at `url`, from disk or the network, decoded at no
    /// more than `maxPixelSize` along its longer side.
    ///
    /// Network images are served from the shared URL cache whenever it has
    /// them, without asking the server whether they've changed: the image
    /// hosts the app uses never change what a URL points to.
    @concurrent
    static func load(_ url: URL, maxPixelSize: Int, session: URLSession) async throws -> CGImage {
        let data: Data
        if url.isFileURL {
            data = try Data(contentsOf: url, options: .mappedIfSafe)
        } else {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (body, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            data = body
        }
        return try decode(data, maxPixelSize: maxPixelSize)
    }

    /// Decodes now rather than at first draw, so scrolling never waits on it,
    /// and only as large as needed, which saves both time and memory.
    static func decode(_ data: Data, maxPixelSize: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { throw ImageDecodingError.unreadable }
        return image
    }

    /// The decode size for a frame of `size` points on a `scale` display,
    /// rounded up to a step so nearby sizes share one decode.
    static func pixelSize(for size: CGSize, scale: CGFloat) -> Int {
        let longest = max(size.width, size.height) * scale * ImageLoadingTokens.fillAllowance
        guard longest > 0 else { return 0 }
        let step = CGFloat(ImageLoadingTokens.pixelSizeStep)
        return min(ImageLoadingTokens.maximumPixelSize, Int((longest / step).rounded(.up) * step))
    }
}
