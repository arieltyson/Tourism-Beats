import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FlightProgressTests {
    @Test func progressClampsAndEditingPreservesStart() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let flight = CountdownFlight(flightNumber: "AC 123", origin: "YVR", destination: "YYZ",
            departure: start.addingTimeInterval(100), timeZoneIdentifier: "America/Vancouver",
            countdownStartedAt: start)
        #expect(flight.countdownProgress(at: start.addingTimeInterval(-10)) == 0)
        #expect(flight.countdownProgress(at: start.addingTimeInterval(50)) == 0.5)
        #expect(flight.countdownProgress(at: start.addingTimeInterval(200)) == 1)
        let form = FlightCountdownFormViewModel(flight: flight)
        form.departure = start.addingTimeInterval(200)
        #expect(form.flight.countdownStartedAt == start)
        #expect(form.flight.countdownProgress(at: start.addingTimeInterval(50)) == 0.25)
    }

    @Test func legacyFlightsDecodeWithoutAStart() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","flightNumber":"AC 123","origin":"YVR","destination":"YYZ","departure":100,"timeZoneIdentifier":"America/Vancouver"}
        """
        let flight = try JSONDecoder().decode(CountdownFlight.self, from: Data(json.utf8))
        #expect(flight.countdownStartedAt == nil)
        #expect(flight.countdownProgress(at: .now) == 0)
    }
}
