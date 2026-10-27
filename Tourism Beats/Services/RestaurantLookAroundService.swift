import MapKit
import OSLog

// MARK: - RestaurantLookAroundService

/// Street-level Look Around snapshots of restaurant frontages.
///
/// Look Around only exists where Apple has collected imagery, so a missing
/// scene is a normal answer, remembered so the card goes straight to its map
/// fallback next time. Request failures are not remembered, so a throttled or
/// offline request is retried on a later visit.
actor RestaurantLookAroundService {
    static let shared = RestaurantLookAroundService()

    private enum Lookup {
        case image(UIImage)
        case noCoverage
    }

    private var cache: [String: Lookup] = [:]
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "RestaurantLookAround"
    )

    func snapshot(
        for restaurant: CityRestaurant,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        guard let latitude = restaurant.latitude, let longitude = restaurant.longitude else {
            return nil
        }

        let key = "\(restaurant.id)_\(Int(size.width))x\(Int(size.height))@\(scale)"

        switch self.cache[key] {
        case let .image(image):
            return image
        case .noCoverage:
            return nil
        case nil:
            break
        }

        do {
            let image = try await Self.generateSnapshot(
                mapItemIdentifier: restaurant.mapItemIdentifier,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                size: size,
                scale: scale
            )
            self.cache[key] = image.map(Lookup.image) ?? .noCoverage
            return image
        } catch {
            self.logger.debug(
                "Look Around unavailable for \(restaurant.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }

    /// Aims at the place itself when Apple Maps knows it, which faces the
    /// camera toward the frontage; otherwise uses the nearest imagery to the
    /// coordinate. Returns `nil` when there's no Look Around coverage.
    @MainActor
    private static func generateSnapshot(
        mapItemIdentifier: String?,
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        scale: CGFloat
    ) async throws -> UIImage? {
        let sceneRequest: MKLookAroundSceneRequest

        if let mapItemIdentifier,
           let identifier = MKMapItem.Identifier(rawValue: mapItemIdentifier),
           let mapItem = try? await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
        {
            sceneRequest = MKLookAroundSceneRequest(mapItem: mapItem)
        } else {
            sceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)
        }

        guard let scene = try await sceneRequest.scene else {
            return nil
        }

        let options = MKLookAroundSnapshotter.Options()
        options.size = size
        options.traitCollection = UITraitCollection(displayScale: scale)

        return try await MKLookAroundSnapshotter(scene: scene, options: options).snapshot.image
    }
}
