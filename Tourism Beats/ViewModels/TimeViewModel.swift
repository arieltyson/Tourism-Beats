import SwiftUI

@MainActor
class TimeViewModel: ObservableObject {
    /// The time zone to display.
    let timeZone: TimeZone

    /// Lazy formatter for the “h:mm a” part.
    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = timeZone
        df.dateFormat = "h:mm a"
        return df
    }()

    /// - Parameter timeZone: The IANA time zone for the city.
    init(timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    /// Returns format like “2:45 PM (GMT +1)” or “9:20 AM (GMT −5)”
    func formattedTime(for date: Date) -> String {
        let timeString = dateFormatter.string(from: date)
        let offsetHours = timeZone.secondsFromGMT(for: date) / 3600

        let offsetLabel: String = {
            switch offsetHours {
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
