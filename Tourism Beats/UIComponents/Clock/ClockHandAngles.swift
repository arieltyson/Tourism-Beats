import Foundation
import SwiftUI

// MARK: - ClockHandAngles

/// Where each hand of the clock points at a moment, in a time zone.
///
/// The angles count every turn since the reference date instead of wrapping
/// at a full circle, so they only ever grow. A hand animating from one tick
/// to the next then always turns forward, even as it passes twelve.
struct ClockHandAngles: Equatable {
    private static let secondsPerMinute: TimeInterval = 60
    private static let secondsPerHour: TimeInterval = 3_600
    private static let secondsPerDialTurn: TimeInterval = 12 * 3_600

    let hour: Angle
    let minute: Angle
    let second: Angle

    init(date: Date, timeZone: TimeZone) {
        // The reference date falls on a midnight in GMT, so seconds counted
        // from it in local time put twelve o'clock at a whole number of turns.
        let localSeconds = date.timeIntervalSinceReferenceDate
            + TimeInterval(timeZone.secondsFromGMT(for: date))

        self.hour = .degrees(localSeconds / Self.secondsPerDialTurn * 360)
        self.minute = .degrees(localSeconds / Self.secondsPerHour * 360)
        self.second = .degrees(localSeconds / Self.secondsPerMinute * 360)
    }
}
