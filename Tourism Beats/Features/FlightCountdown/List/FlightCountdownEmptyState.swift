import SwiftUI

/// Shown before any flight is added; the Add button lives in the toolbar.
struct FlightCountdownEmptyState: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0
    @ScaledMetric private var glyphHeight = FlightCountdownTokens.emptyGlyphHeight

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: SpacingTokens.medium) {
                FlightPathGlyph(progress: progress)
                    .frame(height: glyphHeight)
                Text("Your Next Takeoff")
            }
        } description: {
            Text("Count down to any flight — yours, or a loved one’s.")
        }
        .onAppear {
            guard progress == 0 else { return }
            if reduceMotion {
                progress = FlightPathGlyphTokens.restingProgress
            } else {
                withAnimation(AnimationTokens.journey) { progress = FlightPathGlyphTokens.restingProgress }
            }
        }
    }
}
