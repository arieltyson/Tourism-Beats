import Foundation
import Testing
@testable import Tourism_Beats

struct FlightCalendarTests {
    private let departure = Date(timeIntervalSince1970: 1_797_803_400) // Dec 20, 2026, 21:50 GMT
    private let airports = AirportDirectory.bundled

    private func flight(to destination: String = "YUL", city: String? = "Montréal") -> CountdownFlight {
        CountdownFlight(
            airlineCode: "AC", airlineName: "Air Canada", flightNumber: "308",
            origin: "YVR", originCity: "Vancouver", destination: destination, destinationCity: city,
            departure: departure, timeZoneIdentifier: "America/Vancouver"
        )
    }

    @Test(arguments: [("YVR", "YUL", 4.5, 5.5), ("LHR", "JFK", 7, 8), ("YVR", "SEA", 0.75, 1.25)])
    func estimatedDurationsAreCloseToRealSchedules(from: String, to: String, minimumHours: Double, maximumHours: Double) {
        let hours = FlightDurationEstimator.duration(from: airports.airport(code: from), to: airports.airport(code: to)) / 3_600
        #expect(hours >= minimumHours && hours <= maximumHours, "\(from)–\(to) estimated at \(hours) hours")
    }

    @Test func unknownAirportsFallBackToAnHour() {
        #expect(FlightDurationEstimator.duration(from: .unlisted(code: "XYZ"), to: airports.airport(code: "YUL"))
            == FlightDurationEstimator.fallback)
    }

    @Test func eventDescribesTheFlightInItsDepartureZone() {
        var value = flight()
        let event = FlightCalendarEvent(flight: value)
        #expect(event.title == "Air Canada 308 to Montréal")
        #expect(event.start == departure)
        #expect(event.end > departure)
        #expect(event.timeZone.identifier == "America/Vancouver")
        #expect(event.location == "Vancouver International Airport")
        #expect(event.notes == "YVR → YUL · AC 308")
        #expect(event.fileName == "Air Canada 308 to Montréal.ics")
        value.destination = "LHR"
        #expect(FlightCalendarEvent(flight: value).id == event.id, "Editing a flight keeps its event identity")
    }

    @Test func iCalendarDocumentIsValidAndExact() {
        let event = FlightCalendarEvent(flight: flight())
        let document = FlightICalendarWriter.document(for: event, stampedAt: departure)
        #expect(document.hasPrefix("BEGIN:VCALENDAR\r\nVERSION:2.0\r\n"))
        #expect(document.hasSuffix("END:VEVENT\r\nEND:VCALENDAR\r\n"))
        #expect(document.contains("DTSTART:20261220T215000Z\r\n"))
        #expect(document.contains("SUMMARY:Air Canada 308 to Montréal\r\n"))
        #expect(document.contains("UID:\(event.id)\r\n"))
        #expect(!document.replacing("\r\n", with: "").contains("\n"), "Every line ends in CRLF")
    }

    @Test func textIsEscapedAndLongLinesFoldWithoutSplittingCharacters() throws {
        #expect(FlightICalendarWriter.escaped("a,b;c\\d\ne") == "a\\,b\\;c\\\\d\\ne")
        let line = "SUMMARY:" + String(repeating: "é", count: 60)
        let folded = FlightICalendarWriter.folded(line)
        let pieces = folded.components(separatedBy: "\r\n")
        #expect(pieces.count > 1)
        #expect(pieces.allSatisfy { $0.utf8.count <= 75 })
        #expect(pieces.dropFirst().allSatisfy { $0.hasPrefix(" ") })
        #expect(pieces.enumerated().map { $0.offset == 0 ? $0.element : String($0.element.dropFirst()) }.joined() == line)
    }
}
