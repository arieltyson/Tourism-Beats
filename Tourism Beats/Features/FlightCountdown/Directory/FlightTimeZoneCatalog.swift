import Foundation

/// Every time zone the system knows, described at a flight's departure.
enum FlightTimeZoneCatalog {
    /// All zones alphabetised by place, with offsets in effect at `date`.
    static func options(at date: Date) -> [FlightTimeZoneOption] {
        TimeZone.knownTimeZoneIdentifiers
            .compactMap(TimeZone.init(identifier:))
            .map { FlightTimeZoneOption(timeZone: $0, at: date) }
            .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
    }

    static func filter(_ options: [FlightTimeZoneOption], matching query: String) -> [FlightTimeZoneOption] {
        let query = DirectoryMatch.normalized(query)
        guard !query.isEmpty else { return options }
        return options.filter { $0.matches(query) }
    }
}
