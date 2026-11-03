import SwiftUI

/// Shared look of the countdown card in the app and the widget.
enum FlightCountdownStyle {
    static let spacing: CGFloat = 8
    /// Secondary text over the card's dark backgrounds.
    static let secondaryOpacity: Double = 0.85
    /// The part of the route still to fly.
    static let remainingTrackOpacity: Double = 0.45

    /// The countdown's number, scaled with Dynamic Type from these sizes.
    static let countdownSize: CGFloat = 56
    static let compactCountdownSize: CGFloat = 44
    /// The gap between a countdown's columns, such as months and days.
    static let clockSpacing: CGFloat = 16
    /// Each column shows at least two digits, as a departures board does.
    static let clockDigits = 2
    /// How far a long countdown may shrink to stay on one line.
    static let minimumCountdownScale: CGFloat = 0.5

    /// A 3×3 mesh with its centre nudged up and to the trailing side, so
    /// light pools where the countdown isn't.
    static let meshPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.6, 0.4], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1],
    ]

    /// Darkens a photo at the top and bottom, where the text sits.
    static let scrim: [Gradient.Stop] = [
        .init(color: .black.opacity(0.5), location: 0),
        .init(color: .black.opacity(0.1), location: 0.45),
        .init(color: .black.opacity(0.6), location: 1),
    ]
    static let strongScrim: [Gradient.Stop] = [
        .init(color: .black.opacity(0.7), location: 0),
        .init(color: .black.opacity(0.45), location: 0.45),
        .init(color: .black.opacity(0.8), location: 1),
    ]
}
