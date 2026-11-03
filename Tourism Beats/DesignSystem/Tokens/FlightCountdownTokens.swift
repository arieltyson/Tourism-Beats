import SwiftUI

/// Sizes and timings for Flight Countdown's screens, so its card, rows,
/// and pickers stay in proportion with each other.
enum FlightCountdownTokens {
    /// How long typing pauses before an airport search runs.
    static let searchDebounce: Duration = .milliseconds(150)

    /// The most digits an airline uses for a flight number.
    static let maximumFlightNumberLength = 4
}
