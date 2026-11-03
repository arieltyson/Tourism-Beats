import Foundation

enum FlightCountdownText {
    static func remaining(until departure: Date, from date: Date) -> String {
        let interval = departure.timeIntervalSince(date)
        guard interval > 0 else { return String(localized: "Scheduled departure passed") }
        let duration = Duration.seconds(max(FlightCountdownConfiguration.secondsPerMinute, interval))
        let units: Set<Duration.UnitsFormatStyle.Unit> = interval >= FlightCountdownConfiguration.secondsPerDay
            ? [.days, .hours] : [.hours, .minutes]
        return duration.formatted(.units(
            allowed: units,
            width: .abbreviated, maximumUnitCount: 2
        ))
    }
}
