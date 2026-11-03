import Foundation

enum FlightCountdownText {
    /// The time left in the two largest units that matter, as a departures
    /// board would show it: months and days while it's a month or more away,
    /// days and hours within a month, and hours and minutes on the day.
    ///
    /// Months are counted on the calendar, so they're never approximated as
    /// thirty days. A departure under a minute away still shows a minute.
    /// Empty once the departure has passed.
    static func components(
        until departure: Date, from date: Date, calendar: Calendar = .autoupdatingCurrent
    ) -> [FlightCountdownComponent] {
        guard departure > date else { return [] }
        let units = FlightCountdownUnit.allCases
        let difference = calendar.dateComponents(Set(units.map(\.calendarComponent)), from: date, to: departure)
        let values = units.map { difference.value(for: $0.calendarComponent) ?? 0 }
        let leading = values.firstIndex { $0 > 0 } ?? units.index(before: units.endIndex)
        let first = min(leading, units.count - 2)
        var components = (first...first + 1).map { FlightCountdownComponent(value: values[$0], unit: units[$0]) }
        if components.allSatisfy({ $0.value == 0 }) {
            components[components.count - 1] = FlightCountdownComponent(value: 1, unit: .minute)
        }
        return components
    }

    /// The time left in words, such as "1 month and 17 days", matching what
    /// the card shows.
    static func remaining(
        until departure: Date, from date: Date, calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let components = components(until: departure, from: date, calendar: calendar)
        guard !components.isEmpty else { return String(localized: "Scheduled departure passed") }
        return components.map { $0.phrase(calendar: calendar) }.formatted(.list(type: .and))
    }
}
