import SwiftUI

extension View {
    /// Casts a shadow from an opaque card's rounded outline rather than from
    /// everything drawn in it.
    ///
    /// A shadow applied to a whole card makes SwiftUI render its photo, text,
    /// and effects into an extra offscreen layer just to find its edge, every
    /// frame it moves. A shape's shadow skips that, which keeps scrolling and
    /// swiping smooth. The shape sits behind the card, so the card must be
    /// opaque, as photo cards are.
    func cardShadow(cornerRadius: CGFloat, color: Color, radius: CGFloat, y: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.black)
                .shadow(color: color, radius: radius, y: y)
        }
    }
}
