import PhotosUI
import SwiftUI

/// Chooses a card's background: a designed one, or a photo from the library.
///
/// The photo picker runs outside the app, so no photo library access is
/// requested; only the chosen photo is shared with Tourism Beats.
struct FlightCardDesignPicker: View {
    @Bindable var form: FlightCountdownFormViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                ForEach(FlightCardTheme.gradients) { theme in
                    FlightThemeSwatch(theme: theme, isSelected: form.cardTheme == theme) { form.cardTheme = theme }
                }
                if let photo = form.photo {
                    FlightThemeSwatch(theme: .photo, photo: photo, isSelected: form.cardTheme == .photo) {
                        form.cardTheme = .photo
                    }
                }
                let isPreparing = form.isPreparingPhoto
                let hasPhoto = form.photo != nil
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    FlightPhotoSwatchLabel(isPreparing: isPreparing, hasPhoto: hasPhoto)
                }
                .disabled(form.isPreparingPhoto)
                .accessibilityIdentifier("chooseCardPhoto")
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: form.cardTheme)
        .task(id: photoItem) {
            guard let photoItem else { return }
            do {
                guard let data = try await photoItem.loadTransferable(type: Data.self) else {
                    throw FlightPhotoError.unreadable
                }
                await form.usePhoto(data)
            } catch {
                form.photoErrorMessage = error.localizedDescription
            }
            self.photoItem = nil
        }
    }
}
