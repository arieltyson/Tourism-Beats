import SwiftUI

@MainActor
class TimeViewModel: ObservableObject {
    @Published var timeZone: TimeZone

    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = timeZone
        df.dateFormat = "h:mm a"
        return df
    }()

    /// Map of city names → IANA identifiers
    private static let cityTimeZones: [String: String] = [
        "London": "Europe/London",
        "Paris": "Europe/Paris",
        "Tokyo": "Asia/Tokyo",
        "Berlin": "Europe/Berlin",
        "Madrid": "Europe/Madrid",
        "Barcelona": "Europe/Madrid",
        "Rome": "Europe/Rome",
        "Beijing": "Asia/Shanghai",
        "Cairo": "Africa/Cairo",
        "New Delhi": "Asia/Kolkata",
        "Rio De Janeiro": "America/Sao_Paulo",
        "Moscow": "Europe/Moscow",
        "Amsterdam": "Europe/Amsterdam",
        "Athens": "Europe/Athens",
        "Bangkok": "Asia/Bangkok",
        "Lagos": "Africa/Lagos",
        "Cape Town": "Africa/Johannesburg",
        "Nairobi": "Africa/Nairobi",
        "Stockholm": "Europe/Stockholm",
        "Istanbul": "Europe/Istanbul",
        "Copenhagen": "Europe/Copenhagen",
        "Dubai": "Asia/Dubai",
        "Tehran": "Asia/Tehran",
        "Shanghai": "Asia/Shanghai",
        "Sydney": "Australia/Sydney",
        "Melbourne": "Australia/Melbourne",
        "Buenos Aires": "America/Argentina/Buenos_Aires",
        "Santiago": "America/Santiago",
        "Lima": "America/Lima",
        "Bogota": "America/Bogota",
        "Caracas": "America/Caracas",
        "Port of Spain": "America/Port_of_Spain",
        "Kingston": "America/Jamaica",
        "Mexico City": "America/Mexico_City",
        "Los Angeles": "America/Los_Angeles",
        "San Francisco": "America/Los_Angeles",
        "Vancouver": "America/Vancouver",
        "Houston": "America/Chicago",
        "Dallas": "America/Chicago",
        "Chicago": "America/Chicago",
        "Washington": "America/New_York",
        "New York": "America/New_York",
        "Toronto": "America/Toronto",
        "Montreal": "America/Toronto",
        "Hong Kong": "Asia/Hong_Kong",
        "Seoul": "Asia/Seoul",
        "Mumbai": "Asia/Kolkata",
    ]

    init(cityName: String) {
        self.timeZone = Self.getTimeZone(for: cityName)
    }

    private static func getTimeZone(for cityName: String) -> TimeZone {
        if let identifier = cityTimeZones[cityName],
            let tz = TimeZone(identifier: identifier)
        {
            return tz
        }
        return .current
    }

    /// Returns format like "2:45 PM (GMT +1)" or "9:20 AM (GMT −5)"
    func formattedTime(for date: Date) -> String {
        let timeString = dateFormatter.string(from: date)
        let offset = timeZone.secondsFromGMT() / 3600

        let offsetLabel: String = {
            switch offset {
            case 0:
                return "GMT"
            case let positive where positive > 0:
                return "GMT +\(positive)"
            case let negative where negative < 0:
                return "GMT \(negative)"
            default:
                return "GMT"
            }
        }()

        return "\(timeString) (\(offsetLabel))"
    }
}
