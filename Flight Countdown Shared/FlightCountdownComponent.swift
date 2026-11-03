import Foundation

/// One column of a countdown, such as "17 days".
struct FlightCountdownComponent: Hashable, Sendable {
    let value: Int
    let unit: FlightCountdownUnit

    /// The whole phrase, such as "17 days", pluralized for the locale.
    func phrase(calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        guard let end = calendar.date(byAdding: unit.calendarComponent, value: value, to: start) else {
            return value.formatted(.number.locale(locale))
        }
        return (start..<end).formatted(
            Date.ComponentsFormatStyle(style: .wide, locale: locale, calendar: calendar, fields: [unit.field])
        )
    }

    /// The unit alone, agreeing with the value, such as "days" for 17 or
    /// "day" for 1, so it can be set beneath the number.
    func unitLabel(calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        let number = value.formatted(.number.locale(locale))
        return phrase(calendar: calendar, locale: locale)
            .replacing(number, with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
