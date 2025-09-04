import SwiftUI

@MainActor
class TimeViewModel: ObservableObject {
    @Published var timeZone: TimeZone

    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = self.timeZone
        df.dateFormat = "h:mm a"
        return df
    }()

    init(timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    /// Returns format in the form "2:45 PM (GMT +1)" or "9:20 AM (GMT −5)"
    func formattedTime(for date: Date) -> String {
        let timeString = self.dateFormatter.string(from: date)
        let offsetHours = self.timeZone.secondsFromGMT() / 3_600

        let offsetLabel = switch offsetHours {
        case 0:
            "GMT"
        case let h where h > 0:
            "GMT +\(h)"
        case let h where h < 0:
            "GMT \(h)"
        default:
            "GMT"
        }

        return "\(timeString) (\(offsetLabel))"
    }
}
