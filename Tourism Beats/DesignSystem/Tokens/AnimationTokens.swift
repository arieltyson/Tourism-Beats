// AnimationTokens.swift
// Tourism Beats
//
// Shared animation curves and durations. All animations
// respect accessibilityReduceMotion via the existing
// motionSensitiveAnimation() modifier.

import SwiftUI

/// Animation tokens for consistent motion throughout Tourism Beats.
///
/// Every animation in the app should use one of these tokens
/// rather than defining inline animation parameters.
enum AnimationTokens {
    /// Quick response for interactive feedback (button taps, toggles).
    static let snappy: Animation = .snappy(duration: 0.28, extraBounce: 0.04)

    /// Standard transition for most UI state changes.
    static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.85)

    /// Deliberate transition for content appearing or disappearing.
    static let entrance: Animation = .spring(response: 0.6, dampingFraction: 0.85)

    /// Press feedback for interactive controls.
    static let press: Animation = .spring(response: 0.25, dampingFraction: 0.7)

    /// Duration used for reduced-motion fallback animations.
    static let reducedMotionDuration: Double = 0.18

    /// Stagger delay for sequential list item reveals.
    ///
    /// - Parameter index: The item's position in the list.
    /// - Returns: A snappy animation with a staggered delay.
    static func stagger(index: Int) -> Animation {
        .snappy(duration: 0.28, extraBounce: 0.04)
            .delay(Double(index) * 0.06)
    }
}
