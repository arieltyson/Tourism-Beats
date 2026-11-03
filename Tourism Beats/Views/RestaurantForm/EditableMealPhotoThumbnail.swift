import SwiftUI

// MARK: - EditableMealPhotoThumbnail

struct EditableMealPhotoThumbnail: View {
    let fileURL: URL
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PipelineImage(url: self.fileURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            DelayedProgressView()
                        }
                case let .success(image):
                    FilledImage(image: image)
                case .failure:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))

            Button("Remove Photo", systemImage: "xmark.circle.fill") {
                self.onRemove()
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .tint(AppColors.onImagePrimary)
            .padding(SpacingTokens.xxSmall)
            .accessibilityInputLabels(["Remove Photo", "Delete Photo"])
        }
    }
}
