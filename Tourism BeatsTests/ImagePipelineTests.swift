import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Tourism_Beats

struct ImagePipelineTests {
    private func jpeg(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func file(width: Int, height: Int) throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).jpg")
        try jpeg(width: width, height: height).write(to: url)
        return url
    }

    @Test func imagesAreDecodedNoLargerThanShown() async throws {
        let url = try file(width: 3_000, height: 2_000)
        defer { try? FileManager.default.removeItem(at: url) }
        let pipeline = ImagePipeline()
        let image = try await pipeline.image(for: url, pixelSize: 512)
        #expect(max(image.width, image.height) == 512)
    }

    @Test func decodedImagesAreServedFromMemory() async throws {
        let url = try file(width: 800, height: 600)
        let pipeline = ImagePipeline()
        #expect(pipeline.cachedImage(for: url) == nil)
        _ = try await pipeline.image(for: url, pixelSize: 2_048)
        // The file is gone, so only memory can answer.
        try FileManager.default.removeItem(at: url)
        let cached = try #require(pipeline.cachedImage(for: url, pixelSize: 2_048))
        #expect(cached.width == 800, "An image smaller than asked for is the full image")
        _ = try await pipeline.image(for: url, pixelSize: 512)
    }

    @Test func aSmallerDecodeDoesNotSatisfyALargerView() throws {
        let cache = ImageMemoryCache()
        let url = try #require(URL(string: "https://example.com/a.jpg"))
        let small = try ImageDecoder.decode(try jpeg(width: 2_000, height: 1_000), maxPixelSize: 256)
        cache.insert(small, for: url, requestedPixelSize: 256)
        #expect(cache.image(for: url, pixelSize: 256) != nil)
        #expect(cache.image(for: url, pixelSize: 1_024) == nil)

        let large = try ImageDecoder.decode(try jpeg(width: 2_000, height: 1_000), maxPixelSize: 1_024)
        cache.insert(large, for: url, requestedPixelSize: 1_024)
        cache.insert(small, for: url, requestedPixelSize: 256)
        #expect(cache.image(for: url, pixelSize: 1_024)?.width == 1_024, "A smaller decode never replaces a larger one")
    }

    @Test func requestsForTheSameImageShareOneLoad() async throws {
        let url = try file(width: 1_200, height: 800)
        defer { try? FileManager.default.removeItem(at: url) }
        let pipeline = ImagePipeline()
        async let first = pipeline.image(for: url, pixelSize: 1_024)
        async let second = pipeline.image(for: url, pixelSize: 1_024)
        let (a, b) = try await (first, second)
        #expect(a === b)
    }

    @Test func decodeSizesRoundUpAndStayWithinTheScreen() {
        let step = ImageLoadingTokens.pixelSizeStep
        let small = ImageDecoder.pixelSize(for: CGSize(width: 52, height: 52), scale: 3)
        #expect(small % step == 0 && small >= 52 * 3)
        #expect(ImageDecoder.pixelSize(for: CGSize(width: 2_000, height: 3_000), scale: 3) == ImageLoadingTokens.maximumPixelSize)
        #expect(ImageDecoder.pixelSize(for: .zero, scale: 3) == 0)
    }

    @Test func unreadableDataIsReported() {
        #expect(throws: ImageDecodingError.self) {
            try ImageDecoder.decode(Data("not an image".utf8), maxPixelSize: 256)
        }
    }

    @Test func wikimediaOriginalsGiveWayToSizedThumbnails() throws {
        let thumbnail = try #require(URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Tower.jpg/320px-Tower.jpg"))
        let original = try #require(URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/ab/Tower.jpg"))
        let width = ImageLoadingTokens.wikimediaDisplayWidth

        let large = WikimediaImageURL.preferred(thumbnail: thumbnail, original: original, originalWidth: 6_000)
        #expect(large?.lastPathComponent == "\(width)px-Tower.jpg")
        #expect(large?.deletingLastPathComponent() == thumbnail.deletingLastPathComponent())

        #expect(WikimediaImageURL.preferred(thumbnail: thumbnail, original: original, originalWidth: 900) == original)

        let drawing = try #require(URL(string: "https://upload.wikimedia.org/wikipedia/commons/c/cd/Map.svg"))
        let drawingThumb = try #require(URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Map.svg/320px-Map.svg.png"))
        #expect(WikimediaImageURL.preferred(thumbnail: drawingThumb, original: drawing, originalWidth: 512) == drawingThumb)

        #expect(WikimediaImageURL.resized(original, to: width) == nil)
    }
}
