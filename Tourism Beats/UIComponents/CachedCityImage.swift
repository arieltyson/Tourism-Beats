import SwiftUI

/// Loads a remote city image with a smooth loading transition, placeholder, and failure state.
///
/// Uses `AsyncImage` backed by the shared `URLCache` for automatic disk and memory caching.
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
                    .overlay(ProgressView().tint(.white))
            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: self.contentMode)
            case .failure:
                self.placeholder
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    )
            @unknown default:
                self.placeholder
            }
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
    }
}
