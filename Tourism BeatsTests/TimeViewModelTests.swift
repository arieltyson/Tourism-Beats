import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - TimeViewModelTests

@MainActor
struct TimeViewModelTests {
    /// 2026-11-06 14:45:00 GMT.
    private static let date = Date(timeIntervalSince1970: 1_793_976_300)

    private static func time(in identifier: String, locale: String) throws -> String {
        let timeZone = try #require(TimeZone(identifier: identifier))
        return TimeViewModel(timeZone: timeZone).formattedTime(for: Self.date, locale: Locale(identifier: locale))
    }

    /// Half-hour zones keep their minutes rather than rounding to the hour.
    @Test(arguments: [("Asia/Kolkata", "GMT+5:30"), ("Asia/Kathmandu", "GMT+5:45"), ("America/St_Johns", "GMT-3:30")])
    func offsetsKeepTheirMinutes(identifier: String, offset: String) throws {
        let formatted = try Self.time(in: identifier, locale: "en_US")
        #expect(formatted.hasSuffix("(\(offset))"))
    }

    @Test func wholeHourOffsetsShowTheHourAlone() throws {
        let formatted = try Self.time(in: "Asia/Tokyo", locale: "en_US")
        #expect(formatted.hasSuffix("(GMT+9)"))
    }

    @Test func twelveHourLocalesShowTheDayPeriod() throws {
        let formatted = try Self.time(in: "Etc/GMT", locale: "en_US")
        #expect(formatted.localizedStandardContains("PM"))
    }

    @Test func twentyFourHourLocalesShowTheTwentyFourHourClock() throws {
        let formatted = try Self.time(in: "Etc/GMT", locale: "en_GB")
        #expect(formatted.hasPrefix("14:45"))
        #expect(!formatted.localizedStandardContains("PM"))
    }
}
