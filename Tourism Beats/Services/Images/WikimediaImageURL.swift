import Foundation

/// Picks the Wikimedia image to download for display.
///
/// Wikipedia offers each article image as the original upload, often many
/// megabytes and sometimes an SVG that can't be drawn as a photo, and as
/// thumbnails rendered at any width. A thumbnail at a standard width is a
/// fraction of the size and already cached at Wikimedia's edge.
enum WikimediaImageURL {
    static func preferred(
        thumbnail: URL?,
        original: URL?,
        originalWidth: Int?,
        width: Int = ImageLoadingTokens.wikimediaDisplayWidth
    ) -> URL? {
        // An original no wider than needed is already the right size.
        if let original, let originalWidth, originalWidth <= width, isRaster(original) {
            return original
        }
        // Thumbnails can only be rendered narrower than the original.
        if let thumbnail, let originalWidth, originalWidth > width,
           let resized = resized(thumbnail, to: width) {
            return resized
        }
        if let original, isRaster(original), originalWidth == nil {
            return original
        }
        return thumbnail ?? original
    }

    /// The same thumbnail at another width: `…/thumb/a/ab/Name.jpg/320px-Name.jpg`
    /// becomes `…/1280px-Name.jpg`. Nil for anything that isn't a thumbnail.
    static func resized(_ thumbnail: URL, to width: Int) -> URL? {
        guard thumbnail.path().contains("/thumb/") else { return nil }
        let name = thumbnail.lastPathComponent
        guard let match = name.prefixMatch(of: /\d+px-/) else { return nil }
        let resizedName = "\(width)px-" + name[match.range.upperBound...]
        return thumbnail.deletingLastPathComponent().appending(path: resizedName)
    }

    /// Whether the file is a photo format, rather than a drawing such as SVG.
    static func isRaster(_ url: URL) -> Bool {
        ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(url.pathExtension.lowercased())
    }
}
