import CoreLocation
import SwiftUI

/// Loads a remote city image with a smooth loading transition, placeholder, and failure state.
///
/// Uses `AsyncImage` backed by the shared `URLCache` for automatic disk and memory caching.
/// The view fills whatever bounds its parent establishes, which keeps framing
/// and cropping consistent across cards and hero images.
///
/// When a `fallbackCoordinate` is provided and the remote image fails to load,
/// a satellite map snapshot of the city is shown instead of a blank placeholder.
struct CachedCityImage: View {
    let url: URL
    let contentMode: ContentMode
    let fallbackCoordinate: CLLocationCoordinate2D?

    init(
        url: URL,
        contentMode: ContentMode = .fill,
        fallbackCoordinate: CLLocationCoordinate2D? = nil
    ) {
        self.url = url
        self.contentMode = contentMode
        self.fallbackCoordinate = fallbackCoordinate
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
                if let coordinate = self.fallbackCoordinate {
                    RestaurantMapSnapshot(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        snapshotSize: CGSize(width: 400, height: 300)
                    )
                } else {
                    self.placeholder
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                }
            @unknown default:
                self.placeholder
            }
        }
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
