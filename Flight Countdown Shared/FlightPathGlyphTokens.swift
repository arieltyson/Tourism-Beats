import SwiftUI

/// Proportions of ``FlightPathGlyph``, relative to its height so it scales
/// with whatever size it's given.
enum FlightPathGlyphTokens {
    static let aspectRatio: CGFloat = 2.5
    static let lineWidthRatio: CGFloat = 0.045
    static let endpointRatio: CGFloat = 0.06
    /// Room at the ends and below for the plane and the dots.
    static let insetRatio: CGFloat = 0.2
    /// How high the arc's apex rises above its ends.
    static let riseRatio: CGFloat = 0.55
    static let planeRatio: CGFloat = 0.36
    /// Where the plane rests once it has flown in.
    static let restingProgress: Double = 0.62
    /// Sunset into twilight, from the card palettes.
    static let colors = [FlightCardPalette.sunset[2], FlightCardPalette.sunset[1], FlightCardPalette.aurora[2]]
}
