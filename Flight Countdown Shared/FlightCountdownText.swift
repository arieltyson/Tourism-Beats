import Foundation

enum FlightCountdownText {
    static func remaining(until departure: Date, from date: Date, abbreviated: Bool = true) -> String {
        let interval = departure.timeIntervalSince(date)
        guard interval > 0 else { return String(localized: "Scheduled departure passed") }
        let duration = Duration.seconds(max(FlightCountdownConfiguration.secondsPerMinute, interval))
        let units: Set<Duration.UnitsFormatStyle.Unit> = interval >= FlightCountdownConfiguration.secondsPerDay
            ? [.days, .hours] : [.hours, .minutes]
        return duration.formatted(.units(
            allowed: units,
            width: abbreviated ? .abbreviated : .wide, maximumUnitCount: 2
        ))
    }

    /// The single largest whole unit left, such as "47 days", "5 hours", or
    /// "12 minutes", with its value and unit marked so they can be styled
    /// apart in any language.
    static func headline(until departure: Date, from date: Date) -> AttributedString {
        let interval = departure.timeIntervalSince(date)
        guard interval > 0 else { return AttributedString(localized: "Departed") }
        let unit: Duration.UnitsFormatStyle.Unit = switch interval {
        case FlightCountdownConfiguration.secondsPerDay...: .days
        case FlightCountdownConfiguration.secondsPerHour...: .hours
        default: .minutes
        }
        return Duration.seconds(max(FlightCountdownConfiguration.secondsPerMinute, interval)).formatted(
            .units(allowed: [unit], width: .wide, maximumUnitCount: 1, fractionalPart: .hide(rounded: .down)).attributed
        )
    }
}
