// BucketListTokens.swift
// Tourism Beats
//
// Sizing and timing for the bucket list.

import CoreGraphics
import Foundation

/// Design tokens for the bucket list.
enum BucketListTokens {
    // MARK: - Fireworks

    /// The side of the empty state's fireworks, scaled with Dynamic Type.
    static let fireworksSide: CGFloat = 160

    /// How long one show of bursts runs before it repeats.
    static let fireworksPeriod: TimeInterval = 2.4

    /// How long each burst takes to bloom and fade.
    static let burstLifetime: TimeInterval = 1.6

    /// The sparks in each burst, alternating between an outer and inner ring.
    static let sparksPerBurst = 16

    /// How far the inner ring's sparks fly, as a share of the outer ring's.
    static let innerRingReach: CGFloat = 0.65

    /// How far behind its spark a trail starts, as a share of the burst's life.
    static let trailLag: Double = 0.18

    /// How far a spark flies, as a fraction of the canvas's half-width.
    static let sparkReach: CGFloat = 0.42

    /// How far a spark falls by the time it fades, as the same fraction.
    static let sparkFall: CGFloat = 0.12

    /// A spark's radius, as a fraction of the canvas's half-width.
    static let sparkRadius: CGFloat = 0.035

    // MARK: - Confirmation

    /// How long the card confirming a city added or removed stays up.
    static let confirmationDuration: Duration = .seconds(1.6)
}
