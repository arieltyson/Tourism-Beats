import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FlightProgressTests {
    @Test func progressClampsAndEditingPreservesStart() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let flight = CountdownFlight(airlineCode: "AC", flightNumber: "123", origin: "YVR", destination: "YYZ",
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
        #expect(flight.airlineCode == "AC")
        #expect(flight.flightNumber == "123")
        #expect(flight.destinationName == "YYZ")
    }

    @Test(arguments: [
        ("AC 308", "AC", "308"), ("ac308", "AC", "308"), ("B6 1234", "B6", "1234"),
        ("ACA 12", "ACA", "12"), ("UITEST 901", "", "UITEST 901"), ("12 34", "", "12 34"),
    ])
    func legacyDesignatorsSplitIntoAirlineAndNumber(designator: String, airline: String, number: String) {
        let split = CountdownFlight.split(designator: designator)
        #expect(split.airlineCode == airline)
        #expect(split.flightNumber == number)
    }

    @Test func airlineAndPlacesRoundTrip() throws {
        let flight = CountdownFlight(
            airlineCode: "AC", airlineName: "Air Canada", flightNumber: "308",
            origin: "YVR", originCity: "Vancouver", destination: "YUL", destinationCity: "Montréal",
            departure: Date(timeIntervalSince1970: 1_800_000_000), timeZoneIdentifier: "America/Vancouver"
        )
        let decoded = try JSONDecoder().decode(CountdownFlight.self, from: JSONEncoder().encode(flight))
        #expect(decoded == flight)
        #expect(decoded.designator == "AC 308")
        #expect(decoded.spokenName == "Air Canada 308")
        #expect(decoded.destinationName == "Montréal")
    }

    @Test func pathGlyphPlaneRidesTheArcFromEndToEnd() {
        let size = CGSize(width: 250, height: 100)
        let start = FlightPathArc(size: size, progress: 0)
        let middle = FlightPathArc(size: size, progress: 0.5)
        let end = FlightPathArc(size: size, progress: 1)
        #expect(start.plane == start.origin)
        #expect(end.plane == end.destination)
        #expect(middle.plane.x == size.width / 2)
        #expect(middle.plane.y < middle.origin.y)
        #expect(abs(middle.heading.radians) < 0.000_1)
        #expect(start.heading.radians < 0)
        #expect(end.heading.radians > 0)
        #expect(FlightPathArc(size: size, progress: 2).plane == end.plane)
    }
}
