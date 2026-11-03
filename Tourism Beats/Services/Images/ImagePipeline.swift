import CoreGraphics
import Foundation

/// The one place the app loads images: decoded off the main actor at the
/// size they're shown, kept in memory, and fetched once however many views
/// ask for the same image at the same time.
actor ImagePipeline {
    static let shared = ImagePipeline()

    private struct Request: Hashable {
        let url: URL
        let pixelSize: Int
    }

    private let memory: ImageMemoryCache
    private let session: URLSession
    private var inFlight: [Request: Task<CGImage, any Error>] = [:]

    init(session: URLSession = .shared, memory: ImageMemoryCache = ImageMemoryCache()) {
        self.session = session
        self.memory = memory
    }

    /// An image already decoded in memory, for drawing without waiting.
    nonisolated func cachedImage(for url: URL, pixelSize: Int = 0) -> CGImage? {
        memory.image(for: url, pixelSize: pixelSize)
    }

    func image(for url: URL, pixelSize: Int) async throws -> CGImage {
        if let cached = memory.image(for: url, pixelSize: pixelSize) { return cached }
        let request = Request(url: url, pixelSize: pixelSize)
        if let existing = inFlight[request] { return try await existing.value }
        let session = session
        // Not tied to any one view: a view scrolled away leaves the load to
        // finish for the next one to show.
        let task = Task { try await ImageDecoder.load(url, maxPixelSize: pixelSize, session: session) }
        inFlight[request] = task
        defer { inFlight[request] = nil }
        let image = try await task.value
        memory.insert(image, for: url, requestedPixelSize: pixelSize)
        return image
    }

    /// Starts loading images about to appear, at a size any view can use.
    nonisolated func prefetch(_ urls: some Sequence<URL>) {
        for url in urls where cachedImage(for: url, pixelSize: ImageLoadingTokens.maximumPixelSize) == nil {
            Task(priority: .utility) {
                _ = try? await image(for: url, pixelSize: ImageLoadingTokens.maximumPixelSize)
            }
        }
    }
}
