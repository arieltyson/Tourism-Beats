import SwiftUI

/// Shared look of the countdown card in the app and the widget.
enum FlightCountdownStyle {
    static let spacing: CGFloat = 8
    /// Secondary text over the card's dark backgrounds.
    static let secondaryOpacity: Double = 0.85
    /// The departure line under the destination: a quiet detail beneath it.
    static let departureFont: Font = .footnote
    /// The GMT offset after a departure time, two text styles below the line.
    static let offsetFont: Font = .caption2
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

    /// The contrast every line of text keeps over a photo: WCAG's 4.5:1
    /// for body text, and 7:1 with Increase Contrast.
    static let textContrast: Double = 4.5
    static let increasedTextContrast: Double = 7
    /// Where the card's text sits: destination and date, countdown, route.
    static let scrimBands = [
        FlightScrimBand(span: 0...0.4, minimumOpacity: 0.25),
        FlightScrimBand(span: 0.4...0.76, minimumOpacity: 0),
        FlightScrimBand(span: 0.76...1, minimumOpacity: 0.25),
    ]
    /// The blend between neighbouring bands.
    static let scrimFeather: Double = 0.06
    /// The darkest the scrim gets, so even a white photo still shows.
    static let maximumScrimOpacity: Double = 0.9
    /// How finely a photo is measured: a grid this many cells on a side.
    static let toneGridSide = 16
    /// The scrim's colour: the photo's average hue, this deep and at most
    /// this saturated.
    static let shadeBrightness: Double = 0.12
    static let shadeMaximumSaturation: Double = 0.6

    /// A slight lift in colour and contrast, so the photo still reads as
    /// vivid as it does in Photos once the scrim has darkened it.
    static let photoSaturation: Double = 1.12
    static let photoContrast: Double = 1.06

    /// Lifts white text off a photo where the scrim has eased away.
    static let photoTextShadowOpacity: Double = 0.45
    static let photoTextShadowRadius: CGFloat = 4
    static let photoTextShadowOffset: CGFloat = 1
}
