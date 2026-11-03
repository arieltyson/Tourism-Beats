import SwiftUI

/// One photo in the framing editor: drag to move it, pinch to zoom.
///
/// VoiceOver adjusts the zoom by swiping up or down and moves the photo
/// with actions, so framing never depends on a gesture.
struct FlightPhotoFramingTile: View {
    @Binding var photo: FlightCardImage
    /// The photo's place in the collage, counted from 1.
    let position: Int
    let count: Int

    @State private var frameSize: CGSize = .zero
    /// The framing when the current gesture began, so each change applies
    /// to where it started rather than compounding.
    @State private var gestureStart: FlightPhotoFraming?

    var body: some View {
        FlightFramedPhoto(photo: photo)
            .contentShape(.rect)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { frameSize = $0 }
            .gesture(adjustment)
            .accessibilityElement()
            .accessibilityLabel(count > 1 ? Text("Photo \(position) of \(count)") : Text("Photo"))
            .accessibilityValue(Text("Zoom \(photo.framing.zoom.formatted(.percent.precision(.fractionLength(0))))"))
            .accessibilityHint("Swipe up or down to zoom.")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: photo.framing = photo.framing.zoomed(by: FlightCountdownTokens.framingZoomStep)
                case .decrement: photo.framing = photo.framing.zoomed(by: 1 / FlightCountdownTokens.framingZoomStep)
                @unknown default: break
                }
            }
            .accessibilityActions {
                Button("Move Up") { nudge(x: 0, y: -1) }
                Button("Move Down") { nudge(x: 0, y: 1) }
                Button("Move Left") { nudge(x: -1, y: 0) }
                Button("Move Right") { nudge(x: 1, y: 0) }
                Button("Reset") { photo.framing = .centered }
            }
    }

    private var adjustment: some Gesture {
        SimultaneousGesture(DragGesture(), MagnifyGesture())
            .onChanged { value in
                let start = gestureStart ?? photo.framing
                gestureStart = start
                photo.framing = start
                    .zoomed(by: value.second.map { Double($0.magnification) } ?? 1)
                    .moved(by: value.first?.translation ?? .zero, imageSize: photo.size, frameSize: frameSize)
            }
            .onEnded { _ in gestureStart = nil }
    }

    /// Moves the photo a step of the frame's size, as a short drag would.
    private func nudge(x: CGFloat, y: CGFloat) {
        let step = FlightCountdownTokens.framingNudge
        photo.framing = photo.framing.moved(
            by: CGSize(width: x * step * frameSize.width, height: y * step * frameSize.height),
            imageSize: photo.size, frameSize: frameSize
        )
    }
}
