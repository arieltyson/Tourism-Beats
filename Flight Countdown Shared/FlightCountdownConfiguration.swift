import Foundation

enum FlightCountdownConfiguration {
    static let appGroup = "group.com.arieljtyson.Tourism-Beats"
    static let widgetKind = "FlightCountdown"
    static let deepLink = URL(string: "tourismbeats://flight-countdown")
    static let secondsPerMinute: TimeInterval = 60
    static let secondsPerHour: TimeInterval = 3_600
    static let secondsPerDay: TimeInterval = 86_400
}
