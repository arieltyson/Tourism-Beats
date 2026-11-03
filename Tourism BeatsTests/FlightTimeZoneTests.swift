import Foundation
import Testing
@testable import Tourism_Beats

struct FlightTimeZoneTests {
    /// January 15 and July 15, 2026, at noon GMT.
    private let winter = Date(timeIntervalSince1970: 1_768_478_400)
    private let summer = Date(timeIntervalSince1970: 1_784_116_800)

    private func zone(_ identifier: String) throws -> TimeZone {
        try #require(TimeZone(identifier: identifier))
    }

    @Test func offsetIsTheOneInEffectOnTheDepartureDate() throws {
        let newYork = try zone("America/New_York")
        #expect(newYork.gmtOffsetLabel(at: winter) == "GMT-5")
        #expect(newYork.gmtOffsetLabel(at: summer) == "GMT-4")
    }

    @Test func offsetsFollowTheSystemDatabaseRatherThanAFixedTable() throws {
        let vancouver = try zone("America/Vancouver")
        let expected = vancouver.secondsFromGMT(for: winter) / 3_600
        #expect(vancouver.gmtOffsetLabel(at: winter) == "GMT\(expected)")
    }

    @Test func fractionalAndZeroOffsetsAreReadable() throws {
        #expect(try zone("Asia/Kolkata").gmtOffsetLabel(at: winter) == "GMT+5:30")
        #expect(try zone("Europe/London").gmtOffsetLabel(at: winter) == "GMT+0")
    }

    /// The card's time carries its zone, so 1:50 PM in Vancouver can't be
    /// mistaken for 1:50 PM wherever the widget is read.
    @Test func cardTimesNameTheirTimeZone() throws {
        var vancouver = Calendar(identifier: .gregorian)
        vancouver.timeZone = try zone("America/Vancouver")
        let departure = try #require(vancouver.date(from: DateComponents(year: 2026, month: 12, day: 20, hour: 13, minute: 50)))
        let flight = CountdownFlight(
            airlineCode: "AC", flightNumber: "308", origin: "YVR", destination: "YUL",
            departure: departure, timeZoneIdentifier: "America/Vancouver"
        )
        let offset = vancouver.timeZone.gmtOffsetLabel(at: departure)
        let full = flight.departureSummary(showsTime: true)
        #expect(full.hasSuffix(offset) && full.contains("Sun") && full.contains("1:50"))
        let compact = flight.departureSummary(showsTime: true, includesWeekday: false)
        #expect(compact.hasSuffix(offset) && !compact.contains("Sun"))
        #expect(!flight.departureSummary(showsTime: false).contains("GMT"))
    }

    @Test func optionsNamePlacesAndSearchByOffset() throws {
        let option = FlightTimeZoneOption(timeZone: try zone("America/Argentina/Buenos_Aires"), at: winter)
        #expect(option.city == "Buenos Aires")
        #expect(option.summary == "Buenos Aires (GMT-3)")
        let options = FlightTimeZoneCatalog.options(at: winter)
        let india = FlightTimeZoneCatalog.filter(options, matching: "GMT+5:30")
        #expect(!india.isEmpty)
        #expect(india.allSatisfy { $0.offset == "GMT+5:30" })
        #expect(FlightTimeZoneCatalog.filter(options, matching: "pacific").contains { $0.id == "America/Los_Angeles" })
        #expect(FlightTimeZoneCatalog.filter(options, matching: "").count == options.count)
    }

    @Test func departureLabelUsesTheOffsetInsteadOfAnAbbreviation() {
        let flight = CountdownFlight(
            airlineCode: "AC", flightNumber: "308", origin: "YYZ", destination: "YVR",
            departure: winter, timeZoneIdentifier: "America/Toronto"
        )
        #expect(flight.departureLabel.hasSuffix("GMT-5"))
    }
}
