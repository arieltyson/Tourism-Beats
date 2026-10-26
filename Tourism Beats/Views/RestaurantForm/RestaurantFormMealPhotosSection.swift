import PhotosUI
import SwiftUI

// MARK: - RestaurantFormMealPhotosSection

/// Picks, previews, and removes the meal photos attached to a restaurant.
struct RestaurantFormMealPhotosSection: View {
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let isImporting: Bool
    let errorMessage: String?
    let existingMealPhotos: [RestaurantMealPhoto]
    let stagedMealPhotos: [StagedRestaurantMealPhoto]
    let onRemoveExisting: (RestaurantMealPhoto) -> Void
    let onRemoveStaged: (StagedRestaurantMealPhoto) -> Void

    var body: some View {
        Section {
            PhotosPicker(
                selection: self.$selectedPhotoItems,
                maxSelectionCount: 6,
                matching: .images
            ) {
                Label("Add Meal Photos", systemImage: "photo.on.rectangle.angled")
                    .font(TypographyTokens.cardLabel)
                    .foregroundStyle(AppColors.coral)
            }
            .disabled(self.isImporting)

            if self.isImporting {
                HStack(spacing: SpacingTokens.small) {
                    ProgressView()
                    Text("Importing photos…")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }

            if self.existingMealPhotos.isEmpty, self.stagedMealPhotos.isEmpty {
                Text("Add photos from your camera roll to remember what you ordered.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: SpacingTokens.small) {
                        ForEach(self.existingMealPhotos, id: \.photoIdentifier) { photo in
                            EditableMealPhotoThumbnail(
                                fileURL: RestaurantMealPhotoStore.fileURL(for: photo.relativePath)
                            ) {
                                self.onRemoveExisting(photo)
                            }
                        }

                        ForEach(self.stagedMealPhotos) { photo in
                            EditableMealPhotoThumbnail(
                                fileURL: RestaurantMealPhotoStore.fileURL(for: photo.relativePath)
                            ) {
                                self.onRemoveStaged(photo)
                            }
                        }
                    }
                    .padding(.vertical, SpacingTokens.xxSmall)
                }
                .scrollIndicators(.hidden)
            }
        } header: {
            Text("Meal Photos")
        } footer: {
            Text("Photos are optimized and stored locally to keep the journal fast and space-efficient.")
        }
    }
}
