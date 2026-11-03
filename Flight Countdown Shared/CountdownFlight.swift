import Foundation

struct CountdownFlight: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var flightNumber: String
    var origin: String
    var destination: String
    var departure: Date
    var timeZoneIdentifier: String
    var countdownStartedAt: Date? = Date.now

    func countdownProgress(at date: Date) -> Double {
        guard let start = countdownStartedAt else { return 0 }
        guard departure > start else { return date >= departure ? 1 : 0 }
        return min(1, max(0, date.timeIntervalSince(start) / departure.timeIntervalSince(start)))
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
    var route: String { "\(origin) → \(destination)" }

    var departureLabel: String {
        var style = Date.FormatStyle(date: .abbreviated, time: .shortened)
        style.timeZone = timeZone
        return "\(departure.formatted(style)) \(timeZone.abbreviation(for: departure) ?? timeZoneIdentifier)"
    }

    static func next(in flights: [Self], after date: Date) -> Self? {
        flights.filter { $0.departure > date }.min { $0.departure < $1.departure }
    }
}
