import SwiftUI

/// Frames a card's photos in place: the card as it will look, with each
/// photo moved and zoomed directly beneath the countdown.
struct FlightPhotoFramingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let flight: CountdownFlight
    let onDone: ([UUID: FlightPhotoFraming]) -> Void
    @State private var photos: [FlightCardImage]
    private let original: [FlightPhotoFraming]

    @ScaledMetric private var minimumHeight = FlightCountdownTokens.cardMinimumHeight

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
                        FlightPhotoCollage(count: photos.count) { index in
                            FlightPhotoFramingTile(photo: $photos[index], position: index + 1, count: photos.count)
                        }
                        .background(.black)
                        .overlay { FlightPhotoScrim().allowsHitTesting(false) }
                    }
                    .clipShape(.rect(cornerRadius: FlightCountdownTokens.cardCornerRadius))
                Text(photos.count > 1 ? "Drag or pinch each photo to frame it." : "Drag or pinch the photo to frame it.")
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

    private var hasChanges: Bool { photos.map(\.framing) != original }

    private func reset() {
        withAnimation(reduceMotion ? nil : AnimationTokens.snappy) {
            for index in photos.indices { photos[index].framing = .centered }
        }
    }
}
