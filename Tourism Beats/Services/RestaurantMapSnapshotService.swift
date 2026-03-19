import MapKit

// MARK: - RestaurantMapSnapshotService

actor RestaurantMapSnapshotService {
    static let shared = RestaurantMapSnapshotService()

    private var cache: [String: UIImage] = [:]

    func snapshot(
        latitude: Double,
        longitude: Double,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        let key = "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))_\(Int(size.width))x\(Int(size.height))"

        if let cached = self.cache[key] {
            return cached
        }

        guard let image = await Self.generateSnapshot(
            latitude: latitude,
            longitude: longitude,
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
        latitude: Double,
        longitude: Double,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            latitudinalMeters: 300,
            longitudinalMeters: 300
        )
        options.size = size
        options.scale = scale
        options.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: .flat)

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return snapshot.image
        } catch {
            return nil
        }
    }
}
