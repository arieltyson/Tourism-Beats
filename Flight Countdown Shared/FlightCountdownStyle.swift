import SwiftUI

/// Shared look of the countdown card in the app and the widget.
enum FlightCountdownStyle {
    static let spacing: CGFloat = 8
    /// Secondary text over the card's dark backgrounds.
    static let secondaryOpacity: Double = 0.85
    /// The GMT offset after a departure time, a step below the line's text.
    static let offsetFont: Font = .caption
    /// The part of the route still to fly.
    static let remainingTrackOpacity: Double = 0.45

    /// The countdown's number, scaled with Dynamic Type from these sizes.
    static let countdownSize: CGFloat = 56
    static let compactCountdownSize: CGFloat = 44
    /// The gap between a countdown's columns, such as months and days.
    static let clockSpacing: CGFloat = 16
    /// A countdown's smaller unit, such as days after months, relative to its largest.
    static let secondaryClockScale: CGFloat = 0.55
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

    /// The most photos a card takes turns showing.
    static let maximumPhotoCount = 4
    /// How long each photo fills the card before the next takes its turn.
    static let photoInterval: TimeInterval = 15 * FlightCountdownConfiguration.secondsPerMinute

    /// Darkens a photo only behind the title and the route, easing to clear
    /// between them. A scrim across the whole photo flattens it, so the text
    /// in the middle relies on `photoTextShadow` instead.
    static let scrim: [Gradient.Stop] = [
        .init(color: .black.opacity(0.45), location: 0),
        .init(color: .black.opacity(0.2), location: 0.18),
        .init(color: .clear, location: 0.38),
        .init(color: .clear, location: 0.55),
        .init(color: .black.opacity(0.2), location: 0.78),
        .init(color: .black.opacity(0.5), location: 1),
    ]
    static let strongScrim: [Gradient.Stop] = [
        .init(color: .black.opacity(0.7), location: 0),
        .init(color: .black.opacity(0.45), location: 0.45),
        .init(color: .black.opacity(0.8), location: 1),
    ]

    /// A slight lift in colour and contrast, so the photo still reads as
    /// vivid as it does in Photos once the scrim has darkened it.
    static let photoSaturation: Double = 1.12
    static let photoContrast: Double = 1.06

    /// Lifts white text off a photo where the scrim has eased away.
    static let photoTextShadowOpacity: Double = 0.45
    static let photoTextShadowRadius: CGFloat = 4
    static let photoTextShadowOffset: CGFloat = 1
}
