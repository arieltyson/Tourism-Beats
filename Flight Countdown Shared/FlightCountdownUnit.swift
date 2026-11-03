import Foundation

/// A unit a countdown is told in, from largest to smallest.
enum FlightCountdownUnit: CaseIterable, Sendable {
    case month
    case day
    case hour
    case minute

    var calendarComponent: Calendar.Component {
        switch self {
        case .month: .month
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        }
    }

    var field: Date.ComponentsFormatStyle.Field {
        switch self {
        case .month: .month
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        }
    }
}
