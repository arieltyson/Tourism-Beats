import SwiftUI

/// Shows an image loaded through ``ImagePipeline``, phase by phase, like
/// `AsyncImage`.
///
/// An image already in memory is drawn on the first frame, with no
/// placeholder, so cards scrolled back into view never reload. Others are
/// decoded at the size the view is drawn, measured from its frame.
struct PipelineImage<Content: View>: View {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase
    /// The URL whose image is showing, so a new one starts from a placeholder.
    @State private var shownURL: URL?
    @State private var pixelSize = 0

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        let cached = url.flatMap { ImagePipeline.shared.cachedImage(for: $0) }
        _phase = State(initialValue: cached.map { .success(Image(decorative: $0, scale: 1)) } ?? .empty)
        _shownURL = State(initialValue: cached == nil ? nil : url)
    }

    var body: some View {
        content(phase)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                pixelSize = ImageDecoder.pixelSize(for: size, scale: displayScale)
            }
            .task(id: LoadKey(url: url, pixelSize: pixelSize)) { await load() }
    }

    private struct LoadKey: Equatable {
        let url: URL?
        let pixelSize: Int
    }

    private func load() async {
        guard let url, pixelSize > 0 else { return }
        if let cached = ImagePipeline.shared.cachedImage(for: url, pixelSize: pixelSize) {
            show(cached, from: url, animated: shownURL != url)
            return
        }
        if shownURL != url {
            phase = .empty
        }
        do {
            let image = try await ImagePipeline.shared.image(for: url, pixelSize: pixelSize)
            show(image, from: url, animated: shownURL != url)
        } catch is CancellationError {
            // The view moved on; the pipeline keeps the image for next time.
        } catch {
            if shownURL != url { phase = .failure(error) }
        }
    }

    private func show(_ image: CGImage, from url: URL, animated: Bool) {
        withAnimation(animated && !reduceMotion ? .smooth : nil) {
            phase = .success(Image(decorative: image, scale: 1))
        }
        shownURL = url
    }
}
