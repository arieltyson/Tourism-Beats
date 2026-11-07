import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - ClockHandAnglesTests

struct ClockHandAnglesTests {
    private static let gmt = TimeZone(secondsFromGMT: 0) ?? .gmt

    /// 2026-11-06 03:15:30 GMT.
    private static let morning = Date(timeIntervalSince1970: 1_793_934_930)

    private static func normalized(_ angle: Angle) -> Double {
        let degrees = angle.degrees.truncatingRemainder(dividingBy: 360)
        return degrees < 0 ? degrees + 360 : degrees
    }

    @Test func handsPointAtTheTime() {
        let angles = ClockHandAngles(date: Self.morning, timeZone: Self.gmt)

        #expect(abs(Self.normalized(angles.second) - 180) < 0.001)
        #expect(abs(Self.normalized(angles.minute) - 93) < 0.001)
        #expect(abs(Self.normalized(angles.hour) - 97.75) < 0.001)
    }

    @Test func handsFollowTheCitysTimeZone() throws {
        // A fixed offset, so the test doesn't hang on daylight saving rules.
        let gmtMinusEight = try #require(TimeZone(secondsFromGMT: -8 * 3_600))
        let angles = ClockHandAngles(date: Self.morning, timeZone: gmtMinusEight)

        // 03:15:30 GMT is 19:15:30 the evening before at GMT −8.
        #expect(abs(Self.normalized(angles.hour) - 217.75) < 0.001)
        #expect(abs(Self.normalized(angles.minute) - 93) < 0.001)
    }

    /// Passing twelve, a hand keeps turning forward rather than winding back.
    @Test(arguments: [59.0, 3_599.0, 43_199.0])
    func handsOnlyTurnForward(secondsPastNoon: TimeInterval) {
        let noon = Date(timeIntervalSinceReferenceDate: 43_200)
        let before = ClockHandAngles(date: noon.addingTimeInterval(secondsPastNoon), timeZone: Self.gmt)
        let after = ClockHandAngles(date: noon.addingTimeInterval(secondsPastNoon + 1), timeZone: Self.gmt)

        #expect(after.second > before.second)
        #expect(after.minute > before.minute)
        #expect(after.hour > before.hour)
    }
}
