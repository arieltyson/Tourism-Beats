import Foundation

/// A time zone as the picker lists it: the place, its name, and its offset.
struct FlightTimeZoneOption: Hashable, Identifiable, Sendable {
    let id: String
    /// The place the zone is named after, such as "Vancouver".
    let city: String
    /// The zone's everyday name, such as "Pacific Time".
    let name: String
    /// The offset in effect at the departure, such as "GMT-7".
    let offset: String

    init(timeZone: TimeZone, at date: Date) {
        id = timeZone.identifier
        city = timeZone.cityName
        name = timeZone.localizedName(for: .generic, locale: .current) ?? timeZone.identifier
        offset = timeZone.gmtOffsetLabel(at: date)
    }

    /// Short form for a form row, such as "Vancouver (GMT-7)".
    var summary: String { "\(city) (\(offset))" }

    func matches(_ query: String) -> Bool {
        [city, name, offset, id].contains { $0.localizedStandardContains(query) }
    }
}
