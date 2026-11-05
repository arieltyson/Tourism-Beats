import PhotosUI
import SwiftUI

/// Chooses a card's background: a designed one, or up to four photos from
/// the library that take turns filling the card.
///
/// The photo picker runs outside the app, so no photo library access is
/// requested; only the chosen photos are shared with Tourism Beats.
struct FlightCardDesignPicker: View {
    @Bindable var form: FlightCountdownFormViewModel
    @State private var photoItems: [PhotosPickerItem]
    /// A selection waiting to be loaded once the picker closes.
    @State private var pendingItems: [PhotosPickerItem]?

    init(form: FlightCountdownFormViewModel) {
        self.form = form
        // Photos chosen before show as chosen when the picker opens again.
        _photoItems = State(initialValue: form.photos.compactMap(\.sourceIdentifier).map {
            PhotosPickerItem(itemIdentifier: $0)
        })
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                ForEach(FlightCardTheme.gradients) { theme in
                    FlightThemeSwatch(theme: theme, isSelected: form.cardTheme == theme) { form.cardTheme = theme }
                }
                let images = form.cardImages
                if !images.isEmpty {
                    FlightThemeSwatch(theme: .photo, photo: images.first, isSelected: form.cardTheme == .photo) {
                        form.cardTheme = .photo
                    }
                }
                let isPreparing = form.isPreparingPhoto
                let hasPhotos = !images.isEmpty
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: FlightCountdownStyle.maximumPhotoCount,
                    selectionBehavior: .ordered,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    FlightPhotoSwatchLabel(isPreparing: isPreparing, hasPhotos: hasPhotos)
                }
                .disabled(form.isPreparingPhoto)
                .accessibilityIdentifier("chooseCardPhoto")
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: form.cardTheme)
        .onChange(of: photoItems) { _, items in
            pendingItems = items
        }
        .task(id: pendingItems) {
            guard let items = pendingItems else { return }
            await form.usePhotos(items.map { item in
                FlightPhotoSource(identifier: item.itemIdentifier) {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw FlightPhotoError.unreadable
                    }
                    return data
                }
            })
            pendingItems = nil
        }
    }
}
