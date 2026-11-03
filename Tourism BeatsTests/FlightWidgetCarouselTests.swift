import Foundation
import Testing
@testable import Tourism_Beats

struct FlightWidgetCarouselTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func flight(in hours: Double) -> CountdownFlight {
        CountdownFlight(
            airlineCode: "AC", flightNumber: "\(Int(hours))", origin: "YVR", destination: "YUL",
            departure: now.addingTimeInterval(hours * FlightCountdownConfiguration.secondsPerHour),
            timeZoneIdentifier: "America/Vancouver"
        )
    }

    @Test func showsTheSoonestFlightUntilAnotherIsChosen() throws {
        let later = flight(in: 48), sooner = flight(in: 2), departed = flight(in: -1)
        let flights = [later, departed, sooner]
        let page = try #require(FlightWidgetCarousel.page(in: flights, at: now, selectedID: nil))
        #expect(page.flight.id == sooner.id && page.position == 1 && page.count == 2)

        let chosen = try #require(FlightWidgetCarousel.page(in: flights, at: now, selectedID: later.id))
        #expect(chosen.flight.id == later.id && chosen.position == 2)
    }

    @Test func nextWrapsFromTheLastFlightToTheFirst() {
        let first = flight(in: 1), second = flight(in: 5), third = flight(in: 9)
        let flights = [third, first, second]
        #expect(FlightWidgetCarousel.id(after: nil, in: flights, at: now) == second.id)
        #expect(FlightWidgetCarousel.id(after: second.id, in: flights, at: now) == third.id)
        #expect(FlightWidgetCarousel.id(after: third.id, in: flights, at: now) == first.id)
        #expect(FlightWidgetCarousel.id(after: nil, in: [], at: now) == nil)
    }

    /// Once the chosen flight departs it leaves the carousel, and the widget
    /// moves on to what's still to come.
    @Test func departedFlightsLeaveTheCarousel() throws {
        let first = flight(in: 1), second = flight(in: 5)
        let afterFirst = now.addingTimeInterval(2 * FlightCountdownConfiguration.secondsPerHour)
        let page = try #require(FlightWidgetCarousel.page(in: [first, second], at: afterFirst, selectedID: first.id))
        #expect(page.flight.id == second.id && page.count == 1 && !page.hasOthers)
        let afterAll = now.addingTimeInterval(6 * FlightCountdownConfiguration.secondsPerHour)
        #expect(FlightWidgetCarousel.page(in: [first, second], at: afterAll, selectedID: nil) == nil)
    }

    @Test func selectionIsRememberedInTheAppGroup() throws {
        let defaults = try #require(UserDefaults(suiteName: "FlightWidgetCarouselTests"))
        defer { defaults.removePersistentDomain(forName: "FlightWidgetCarouselTests") }
        let id = UUID()
        FlightWidgetSelection.select(id, in: defaults)
        #expect(FlightWidgetSelection.selectedID(in: defaults) == id)
        FlightWidgetSelection.select(nil, in: defaults)
        #expect(FlightWidgetSelection.selectedID(in: defaults) == nil)
    }
}
