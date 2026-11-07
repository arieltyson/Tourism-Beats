import Foundation
import SwiftUI

// MARK: - ClockSweep

/// How the hands travel between the clock's once-a-second updates.
///
/// Redrawing the hands every frame would keep the app busy for as long as the
/// clock is on screen. Instead, each update hands the system one linear
/// animation to the hands' position a tick from now, which arrives just as
/// the next update starts the next one. The hands glide continuously and
/// always point at the true time.
enum ClockSweep {
    /// The moment the hands are drawn at for an update.
    ///
    /// Sweeping, the hands set off toward where they belong at the next tick.
    /// Otherwise they show the update's own moment.
    static func target(for date: Date, sweeps: Bool) -> Date {
        sweeps ? date.addingTimeInterval(ClockFaceTokens.tickInterval) : date
    }

    /// The animation from one update to the next, if any.
    ///
    /// Only consecutive ticks sweep. After the clock has been paused off
    /// screen, the hands jump straight to the time instead of spinning
    /// through every minute they missed.
    static func animation(from oldDate: Date, to newDate: Date, sweeps: Bool) -> Animation? {
        let tolerance = ClockFaceTokens.tickInterval / 2
        let elapsed = newDate.timeIntervalSince(oldDate)
        guard sweeps, abs(elapsed - ClockFaceTokens.tickInterval) < tolerance else { return nil }
        return .linear(duration: ClockFaceTokens.tickInterval)
    }
}
