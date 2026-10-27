import SwiftUI

// MARK: - RestaurantPreviewImage

/// A street-level Look Around view of the restaurant where Apple has imagery,
/// and a tilted satellite view with the restaurant marked everywhere else.
///
/// Both are requested together so places without Look Around coverage don't
/// wait for that answer before their map starts loading.
struct RestaurantPreviewImage: View {
    let restaurant: CityRestaurant
    let snapshotSize: CGSize

    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {
            AppColors.surfaceSecondary.opacity(0.6)

            if let image {
                FilledImage(image: Image(uiImage: image))
            }
        }
        .animation(.smooth(duration: 0.4), value: self.image != nil)
        .accessibilityHidden(true)
        .task(id: self.restaurant.id) {
            self.image = await Self.preview(
                for: self.restaurant,
                size: self.snapshotSize,
                scale: self.displayScale
            )
        }
    }

    private static func preview(
        for restaurant: CityRestaurant,
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        guard let latitude = restaurant.latitude, let longitude = restaurant.longitude else {
            return nil
        }

        // Unstructured so a Look Around answer is shown without waiting for the
        // map to finish; the map still completes into its cache.
        let map = Task {
            await RestaurantMapSnapshotService.shared.snapshot(
                latitude: latitude,
                longitude: longitude,
                size: size,
                scale: scale,
                marksLocation: true
            )
        }

        if let streetLevel = await RestaurantLookAroundService.shared.snapshot(
            for: restaurant,
            size: size,
            scale: scale
        ) {
            return streetLevel
        }
        return await map.value
    }
}
