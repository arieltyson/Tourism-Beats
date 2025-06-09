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

    init(timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    /// Returns format in the form "2:45 PM (GMT +1)" or "9:20 AM (GMT −5)"
    func formattedTime(for date: Date) -> String {
        let timeString = dateFormatter.string(from: date)
        let offsetHours = timeZone.secondsFromGMT() / 3600

        let offsetLabel: String = {
            switch offsetHours {
            case 0:
                return "GMT"
            case let h where h > 0:
                return "GMT +\(h)"
            case let h where h < 0:
                return "GMT \(h)"
            default:
                return "GMT"
            }
        }()

        return "\(timeString) (\(offsetLabel))"
    }
}
