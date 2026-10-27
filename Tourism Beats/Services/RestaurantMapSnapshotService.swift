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
        scale: CGFloat,
        marksLocation: Bool = false
    ) async -> UIImage? {
        let key = "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))_\(Int(size.width))x\(Int(size.height))@\(scale)_\(marksLocation)"

        if let cached = self.cache[key] {
            return cached
        }

        guard let image = await Self.generateSnapshot(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            size: size,
            scale: scale,
            marksLocation: marksLocation
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
        scale: CGFloat,
        marksLocation: Bool
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

        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else {
            return nil
        }

        guard marksLocation else {
            return snapshot.image
        }

        return self.image(snapshot.image, markedAt: snapshot.point(for: coordinate))
    }

    /// Centers a marker on `point`, so the place is findable in the tilted view.
    @MainActor
    private static func image(_ image: UIImage, markedAt point: CGPoint) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.white, .systemRed]))
        guard let pin = UIImage(systemName: "mappin.circle.fill", withConfiguration: configuration) else {
            return image
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale

        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            image.draw(at: .zero)

            let pinOrigin = CGPoint(x: point.x - pin.size.width / 2, y: point.y - pin.size.height / 2)
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.45).cgColor)
            pin.draw(at: pinOrigin)
        }
    }
}
