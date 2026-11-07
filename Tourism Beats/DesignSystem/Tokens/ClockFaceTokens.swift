// ClockFaceTokens.swift
// Tourism Beats
//
// Proportions and timing for the analog city clock.

import CoreGraphics
import Foundation

/// Design tokens for the analog city clock.
///
/// The clock is an illustration that scales with its card, so every length
/// is a fraction of the dial's radius rather than a point size. That keeps
/// the face in proportion at any size.
enum ClockFaceTokens {
    // MARK: - Dial

    /// Gap between the rim and the outer end of each minute tick.
    static let tickInset: CGFloat = 0.05

    /// Length of every minute tick.
    static let tickLength: CGFloat = 0.08

    /// Width of the ticks between the hours.
    static let minuteTickWidth: CGFloat = 0.014

    /// Width of the ticks that sit on the hours, beside each numeral.
    static let hourTickWidth: CGFloat = 0.03

    /// Clear space kept between the numerals and the ticks.
    static let numeralGap: CGFloat = 0.05

    /// The numerals' point size.
    static let numeralSize: CGFloat = 0.23

    /// Opacity of the minute ticks against the face.
    static let tickOpacity: Double = 0.4

    /// Tick opacity when Increase Contrast is on.
    static let increasedContrastTickOpacity: Double = 0.75

    // MARK: - Hands

    /// Length of the hour hand.
    static let hourHandLength: CGFloat = 0.5

    /// Length of the minute hand.
    static let minuteHandLength: CGFloat = 0.8

    /// Width of the broad part of the hour and minute hands.
    static let handWidth: CGFloat = 0.075

    /// Length of the slim neck joining the hour and minute hands to the hub.
    static let handNeckLength: CGFloat = 0.14

    /// Width of that neck.
    static let handNeckWidth: CGFloat = 0.03

    /// Length of the second hand.
    static let secondHandLength: CGFloat = 0.9

    /// Length of the second hand's counterweight, behind the hub.
    static let secondHandTail: CGFloat = 0.2

    /// Width of the second hand.
    static let secondHandWidth: CGFloat = 0.02

    /// Diameter of the hub the hour and minute hands turn on.
    static let hubDiameter: CGFloat = 0.12

    /// Diameter of the second hand's cap over the hub.
    static let capDiameter: CGFloat = 0.08

    /// Diameter of the pin at the center of the cap.
    static let pinDiameter: CGFloat = 0.03

    // MARK: - Time

    /// The local hours the face is shown light; it turns dark for the night.
    static let daytimeHours = 6 ..< 18

    /// How often the hands move. With motion allowed, they sweep through
    /// each interval rather than jumping at its end.
    static let tickInterval: TimeInterval = 1

    // MARK: - Card

    /// The largest the clock grows in the city's time card.
    static let cardMaximumSide: CGFloat = 120
}
