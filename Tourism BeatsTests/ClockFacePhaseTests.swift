import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - ClockFacePhaseTests

struct ClockFacePhaseTests {
    private static let gmt = TimeZone(secondsFromGMT: 0) ?? .gmt
    private static let midnight = Date(timeIntervalSinceReferenceDate: 0)

    @Test(arguments: [(6, ClockFacePhase.day), (12, .day), (17, .day), (18, .night), (23, .night), (0, .night), (5, .night)])
    func phaseFollowsTheLocalHour(hour: Int, expected: ClockFacePhase) {
        let date = Self.midnight.addingTimeInterval(TimeInterval(hour * 3_600))
        #expect(ClockFacePhase(date: date, timeZone: Self.gmt) == expected)
    }

    @Test func phaseIsTheCitys() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        // Midnight in GMT is 9 AM in Tokyo.
        #expect(ClockFacePhase(date: Self.midnight, timeZone: tokyo) == .day)
    }
}
