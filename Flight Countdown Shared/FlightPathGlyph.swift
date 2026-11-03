import SwiftUI

/// A flight drawn as its route: an arc from an origin dot to a destination
/// ring, flown in a warm gradient up to the plane and dashed beyond it.
///
/// It echoes the progress track on every card, so the empty screen and the
/// widget already speak the feature's visual language. Set `progress` inside
/// an animation to fly the plane along the arc.
struct FlightPathGlyph: View, Animatable {
    /// How far along the arc the plane is, from 0 to 1.
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private enum Symbol: Hashable { case plane }

    var body: some View {
        Canvas { context, size in
            let arc = FlightPathArc(size: size, progress: progress)
            let lineWidth = size.height * FlightPathGlyphTokens.lineWidthRatio
            context.stroke(
                arc.remaining, with: .style(.secondary),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [lineWidth, lineWidth * 2])
            )
            context.stroke(
                arc.flown,
                with: .linearGradient(
                    Gradient(colors: FlightPathGlyphTokens.colors),
                    startPoint: arc.origin, endPoint: arc.destination
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            let radius = size.height * FlightPathGlyphTokens.endpointRatio
            context.fill(Path(ellipseIn: arc.origin.square(radius: radius)), with: .color(FlightPathGlyphTokens.colors[0]))
            context.stroke(Path(ellipseIn: arc.destination.square(radius: radius)), with: .style(.secondary), lineWidth: lineWidth)

            guard let plane = context.resolveSymbol(id: Symbol.plane), plane.size.height > 0 else { return }
            var placed = context
            placed.translateBy(x: arc.plane.x, y: arc.plane.y)
            placed.rotate(by: arc.heading)
            let scale = size.height * FlightPathGlyphTokens.planeRatio / plane.size.height
            placed.scaleBy(x: scale, y: scale)
            placed.draw(plane, at: .zero)
        } symbols: {
            Image(systemName: "airplane")
                .font(.largeTitle)
                .tag(Symbol.plane)
        }
        .aspectRatio(FlightPathGlyphTokens.aspectRatio, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
