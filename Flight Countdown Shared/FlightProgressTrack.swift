import SwiftUI

/// How far along the wait is, drawn as a plane on its route.
struct FlightProgressTrack: View {
    @Environment(\.layoutDirection) private var layoutDirection
    let progress: Double

    var body: some View {
        FlightProgressLayout(progress: progress, rightToLeft: layoutDirection == .rightToLeft) {
            Capsule().fill(.white)
            Capsule().fill(.white.opacity(FlightCountdownStyle.remainingTrackOpacity))
            Circle().fill(.white)
                .frame(width: FlightProgressTokens.endpointDiameter, height: FlightProgressTokens.endpointDiameter)
            Circle().fill(.white)
                .frame(width: FlightProgressTokens.endpointDiameter, height: FlightProgressTokens.endpointDiameter)
            Image(systemName: "airplane")
                .font(.body)
                .rotationEffect(.degrees(layoutDirection == .rightToLeft ? 180 : 0))
        }
        .accessibilityHidden(true)
    }
}
