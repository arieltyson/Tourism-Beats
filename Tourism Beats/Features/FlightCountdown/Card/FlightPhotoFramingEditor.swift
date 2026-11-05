import SwiftUI

/// Frames a card's photos in place: the card as it will look, with the
/// chosen photo filling it, moved and zoomed directly beneath the countdown.
/// Each photo fills the whole card in its turn, so each is framed alone.
struct FlightPhotoFramingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let flight: CountdownFlight
    let onDone: ([UUID: FlightPhotoFraming]) -> Void
    @State private var photos: [FlightCardImage]
    /// The photo being framed.
    @State private var selection = 0
    private let original: [FlightPhotoFraming]

    @ScaledMetric private var minimumHeight = FlightCountdownTokens.cardMinimumHeight
    @ScaledMetric private var thumbnailSize = FlightCountdownTokens.swatchSize

    init(flight: CountdownFlight, photos: [FlightCardImage], onDone: @escaping ([UUID: FlightPhotoFraming]) -> Void) {
        self.flight = flight
        self.onDone = onDone
        _photos = State(initialValue: photos)
        original = photos.map(\.framing)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: SpacingTokens.medium) {
                FlightCountdownFace(flight: flight, date: .now)
                    .padding(SpacingTokens.large)
                    .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
                    // The countdown shows where text will sit; touches reach the photos beneath.
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .background {
                        if photos.indices.contains(selection) {
                            FlightPhotoFramingTile(photo: $photos[selection], position: selection + 1, count: photos.count)
                                // A new photo starts its own gesture.
                                .id(photos[selection].id)
                                .overlay { FlightPhotoScrim().allowsHitTesting(false) }
                        }
                    }
                    .clipShape(.rect(cornerRadius: FlightCountdownTokens.cardCornerRadius))
                if photos.count > 1 { chooser }
                Text(photos.count > 1 ? "Drag or pinch to frame the photo, then choose the next one below." : "Drag or pinch the photo to frame it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .padding(SpacingTokens.medium)
            .navigationTitle(photos.count > 1 ? "Adjust Photos" : "Adjust Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .confirm) {
                        onDone(Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.framing) }))
                        dismiss()
                    }
                    .disabled(!hasChanges)
                    .accessibilityIdentifier("doneFramingPhotos")
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset", systemImage: "arrow.counterclockwise", action: reset)
                        .disabled(photos.allSatisfy(\.framing.isCentered))
                }
            }
            .sensoryFeedback(.selection, trigger: photos.allSatisfy(\.framing.isCentered)) { _, isCentered in isCentered }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(hasChanges)
    }

    /// The card's photos as thumbnails, framed as they are on the card;
    /// choosing one frames it.
    private var chooser: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            ForEach(photos.indices, id: \.self) { index in
                let isSelected = index == selection
                Button { selection = index } label: {
                    FlightFramedPhoto(photo: photos[index])
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipShape(.rect(cornerRadius: FlightCountdownTokens.thumbnailCornerRadius))
                        .padding(FlightCountdownTokens.swatchRingInset)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: FlightCountdownTokens.thumbnailCornerRadius + FlightCountdownTokens.swatchRingInset)
                                    .strokeBorder(.tint, lineWidth: FlightCountdownTokens.swatchRingWidth)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Photo \(index + 1) of \(photos.count)"))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var hasChanges: Bool { photos.map(\.framing) != original }

    private func reset() {
        withAnimation(reduceMotion ? nil : AnimationTokens.snappy) {
            for index in photos.indices { photos[index].framing = .centered }
        }
    }
}
