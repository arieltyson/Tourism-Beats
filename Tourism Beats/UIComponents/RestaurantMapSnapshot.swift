import SwiftUI

// MARK: - RestaurantMapSnapshot

struct RestaurantMapSnapshot: View {
    let latitude: Double
    let longitude: Double
    let snapshotSize: CGSize

    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {
            AppColors.surfaceSecondary.opacity(0.6)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .animation(.smooth(duration: 0.4), value: self.image != nil)
        .task(id: "\(self.latitude)_\(self.longitude)") {
            self.image = await RestaurantMapSnapshotService.shared.snapshot(
                latitude: self.latitude,
                longitude: self.longitude,
                size: self.snapshotSize,
                scale: self.displayScale
            )
        }
    }
}
