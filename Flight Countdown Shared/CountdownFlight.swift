import Foundation

/// A flight someone is counting down to: their own, or a loved one's.
///
/// Shared by the app, which writes flights, and the widget, which reads them.
struct CountdownFlight: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    /// The airline's IATA designator, such as `AC`.
    var airlineCode: String
    var airlineName: String?
    /// The number within the airline, such as `308`.
    var flightNumber: String
    /// The departure airport's IATA code.
    var origin: String
    var originCity: String?
    /// The arrival airport's IATA code.
    var destination: String
    var destinationCity: String?
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

    /// The code printed on boarding passes, such as "AC 308".
    var designator: String {
        airlineCode.isEmpty ? flightNumber : "\(airlineCode) \(flightNumber)"
    }

    /// The flight as people say it, such as "Air Canada 308".
    var spokenName: String {
        guard let airlineName else { return designator }
        return "\(airlineName) \(flightNumber)"
    }

    /// Where the flight lands, by city when it's known.
    var destinationName: String { destinationCity ?? destination }

    /// The departure in the airport's local time with its GMT offset, such as
    /// "Dec 20, 2026 at 1:50 PM GMT-7". Offsets are unambiguous where
    /// abbreviations such as "MST" are not.
    var departureLabel: String {
        var style = Date.FormatStyle(date: .abbreviated, time: .shortened)
        style.timeZone = timeZone
        return "\(departure.formatted(style)) \(timeZone.gmtOffsetLabel(at: departure))"
    }

    static func next(in flights: [Self], after date: Date) -> Self? {
        flights.filter { $0.departure > date }.min { $0.departure < $1.departure }
    }

    /// Splits a combined designator such as "AC308" or "AC 308" into its
    /// airline and number. Anything else stays whole as the number.
    static func split(designator: String) -> (airlineCode: String, flightNumber: String) {
        let value = designator.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let match = value.wholeMatch(of: /([A-Z0-9]{2}[A-Z]?)\s*(\d{1,4}[A-Z]?)/),
              match.1.contains(where: \.isLetter) else { return ("", value) }
        return (String(match.1), String(match.2))
    }
}

extension CountdownFlight {
    private enum CodingKeys: String, CodingKey {
        case id, airlineCode, airlineName, flightNumber
        case origin, originCity, destination, destinationCity
        case departure, timeZoneIdentifier, countdownStartedAt
    }

    /// Flights saved before the airline was chosen separately stored the whole
    /// designator in `flightNumber`; they're split on the way in.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let number = try container.decode(String.self, forKey: .flightNumber)
        if let airlineCode = try container.decodeIfPresent(String.self, forKey: .airlineCode) {
            self.airlineCode = airlineCode
            flightNumber = number
        } else {
            (airlineCode, flightNumber) = Self.split(designator: number)
        }
        id = try container.decode(UUID.self, forKey: .id)
        airlineName = try container.decodeIfPresent(String.self, forKey: .airlineName)
        origin = try container.decode(String.self, forKey: .origin)
        originCity = try container.decodeIfPresent(String.self, forKey: .originCity)
        destination = try container.decode(String.self, forKey: .destination)
        destinationCity = try container.decodeIfPresent(String.self, forKey: .destinationCity)
        departure = try container.decode(Date.self, forKey: .departure)
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        countdownStartedAt = try container.decodeIfPresent(Date.self, forKey: .countdownStartedAt)
    }
}
