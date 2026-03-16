import SwiftUI

/// Displays album art inside a stable square card so artwork never stretches
/// or overflows its intended visual frame.
struct MusicArtworkCard: View {
    let artworkURL: URL?

    var body: some View {
        Group {
            if let artworkURL {
                AsyncImage(url: artworkURL, transaction: .init(animation: .smooth)) { phase in
                    switch phase {
                    case .empty:
                        self.loadingArtwork
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        self.placeholderArtwork
                    @unknown default:
                        self.placeholderArtwork
                    }
                }
            } else {
                self.placeholderArtwork
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
        .contentShape(.rect(cornerRadius: 28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var loadingArtwork: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                ProgressView()
                    .tint(.white)
            }
    }

    private var placeholderArtwork: some View {
        Image("placeholder_artwork")
            .resizable()
            .scaledToFill()
    }
}
