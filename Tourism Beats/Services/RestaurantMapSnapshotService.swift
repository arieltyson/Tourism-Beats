import MapKit

// MARK: - RestaurantMapSnapshotService

actor RestaurantMapSnapshotService {
    static let shared = RestaurantMapSnapshotService()

    /// A tilted camera reads as a place rather than a plan, and realistic
    /// elevation renders buildings in 3D wherever Apple has that data.
    private static let cameraDistance: CLLocationDistance = 450
    private static let cameraPitch: CGFloat = 55

    private var cache: [String: UIImage] = [:]

    func snapshot(
        latitude: Double,
        longitude: Double,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        let key = "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))_\(Int(size.width))x\(Int(size.height))@\(scale)"

        if let cached = self.cache[key] {
            return cached
        }

        guard let image = await Self.generateSnapshot(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            size: size,
            scale: scale
        ) else {
            return nil
        }

        self.cache[key] = image
        return image
    }

    @MainActor
    private static func generateSnapshot(
        coordinate: CLLocationCoordinate2D,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.camera = MKMapCamera(
            lookingAtCenter: coordinate,
            fromDistance: self.cameraDistance,
            pitch: self.cameraPitch,
            heading: 0
        )
        options.size = size
        options.scale = scale
        options.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: .realistic)

        return try? await MKMapSnapshotter(options: options).start().image
    }
}
