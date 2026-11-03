import Foundation

/// Which upcoming flight the widget shows. Flights leave the carousel the
/// moment they depart, so only the ones still to come remain.
enum FlightWidgetCarousel {
    /// Flights still to depart at `date`, soonest first.
    static func upcoming(in flights: [CountdownFlight], at date: Date) -> [CountdownFlight] {
        flights.filter { $0.departure > date }.sorted { $0.departure < $1.departure }
    }

    /// The chosen flight while it's still to come, otherwise the next to depart.
    static func page(in flights: [CountdownFlight], at date: Date, selectedID: UUID?) -> FlightWidgetPage? {
        let upcoming = upcoming(in: flights, at: date)
        guard !upcoming.isEmpty else { return nil }
        let index = upcoming.firstIndex { $0.id == selectedID } ?? upcoming.startIndex
        return FlightWidgetPage(flight: upcoming[index], position: index + 1, count: upcoming.count)
    }

    /// The flight after the one shown, wrapping from the last to the first.
    static func id(after selectedID: UUID?, in flights: [CountdownFlight], at date: Date) -> UUID? {
        let upcoming = upcoming(in: flights, at: date)
        guard let page = page(in: flights, at: date, selectedID: selectedID) else { return nil }
        return upcoming[page.position % upcoming.count].id
    }
}
