import SwiftUI

/// Loads a remote city image with a smooth loading transition, placeholder, and failure state.
///
/// Uses `AsyncImage` backed by the shared `URLCache` for automatic disk and memory caching.
/// The view fills whatever bounds its parent establishes, which keeps framing
/// and cropping consistent across cards and hero images.
struct CachedCityImage: View {
    let url: URL
    let contentMode: ContentMode

    init(url: URL, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }

    var body: some View {
        AsyncImage(url: self.url, transaction: .init(animation: .smooth)) { phase in
            switch phase {
            case .empty:
                self.placeholder
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            case let .success(image):
                self.scaledImage(image)
            case .failure:
                self.placeholder
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.55))
                    }
            @unknown default:
                self.placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
    }

    @ViewBuilder
    private func scaledImage(_ image: Image) -> some View {
        switch self.contentMode {
        case .fill:
            image
                .resizable()
                .scaledToFill()
        case .fit:
            image
                .resizable()
                .scaledToFit()
        @unknown default:
            image
                .resizable()
                .scaledToFill()
        }
    }
}
