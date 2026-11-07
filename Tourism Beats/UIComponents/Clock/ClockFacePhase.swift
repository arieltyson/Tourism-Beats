import Foundation

// MARK: - ClockFacePhase

/// Whether it's day or night where the clock is, which sets its face.
///
/// As in the Clock app's world clocks, a light face means day in that city
/// and a dark one night, so the time of day reads at a glance.
enum ClockFacePhase: Equatable {
    case day
    case night

    init(date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        self = ClockFaceTokens.daytimeHours.contains(hour) ? .day : .night
    }
}
