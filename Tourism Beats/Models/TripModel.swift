import Foundation
import SwiftData
import SwiftUI

// MARK: - Trip

/// A user-created travel itinerary containing days and activities.
///
/// All stored properties use defaults or optionals for CloudKit compatibility.
/// Relationships use cascade delete so removing a trip removes its days/activities.
@Model
final class Trip {
    var name: String = ""
    var city: String = ""
    var country: String = ""
    var isSample: Bool = false
    var startDate: Date?
    var endDate: Date?
    var notes: String?
    var statusRaw: String = TripStatus.upcoming.rawValue
    var dateCreated: Date = Date.now

    @Relationship(deleteRule: .cascade)
    var days: [TripDay]?

    init(
        name: String,
        city: String,
        country: String = "",
        isSample: Bool = false,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil,
        status: TripStatus = .upcoming
    ) {
        self.name = name
        self.city = city
        self.country = country
        self.isSample = isSample
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.statusRaw = status.rawValue
        self.dateCreated = Date.now
    }

    // MARK: Computed

    var status: TripStatus {
        get { TripStatus(rawValue: self.statusRaw) ?? .upcoming }
        set { self.statusRaw = newValue.rawValue }
    }

    var sortedDays: [TripDay] {
        (self.days ?? []).sorted { $0.dayNumber < $1.dayNumber }
    }

    var displayLocation: String {
        switch (
            self.city.trimmingCharacters(in: .whitespacesAndNewlines),
            self.country.trimmingCharacters(in: .whitespacesAndNewlines)
        ) {
        case ("", ""):
            "Custom trip"
        case let ("", country):
            country
        case let (city, ""):
            city
        case let (city, country):
            "\(city), \(country)"
        }
    }

    var dayCount: Int {
        (self.days ?? []).count
    }

    var activityCount: Int {
        self.sortedDays.reduce(0) { partialResult, day in
            partialResult + day.activityCount
        }
    }

    var completedActivityCount: Int {
        self.sortedDays.reduce(0) { partialResult, day in
            partialResult + day.completedActivityCount
        }
    }

    var progressLabel: String? {
        guard self.activityCount > 0 else { return nil }
        return
            "\(self.completedActivityCount.formatted(.number))/\(self.activityCount.formatted(.number)) done"
    }

    var notesSummary: String? {
        guard let trimmedNotes else { return nil }
        return trimmedNotes
    }

    var scheduleSummaryLabel: String {
        let dayLabel =
            self.dayCount == 1
            ? "1 day"
            : "\(self.dayCount.formatted(.number)) days"

        guard self.activityCount > 0 else { return dayLabel }

        let activityLabel =
            self.activityCount == 1
            ? "1 activity"
            : "\(self.activityCount.formatted(.number)) activities"
        return "\(dayLabel) • \(activityLabel)"
    }

    var dateRangeLabel: String? {
        guard let start = self.startDate else { return nil }
        let formatter = Self.dateRangeFormatter
        if let end = self.endDate {
            return
                "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
        return formatter.string(from: start)
    }

    var nextDayNumber: Int {
        let maxDay = (self.days ?? []).map(\.dayNumber).max() ?? 0
        return maxDay + 1
    }

    var nextDayDate: Date? {
        self.sortedDays.compactMap(\.date).last.flatMap { lastDate in
            Calendar.current.date(byAdding: .day, value: 1, to: lastDate)
        }
    }

    var trimmedNotes: String? {
        guard let notes else { return nil }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNotes.isEmpty ? nil : trimmedNotes
    }

    private static let dateRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - TripDay

/// A single day within a trip's itinerary.
@Model
final class TripDay {
    var dayNumber: Int = 1
    var date: Date?
    var label: String?

    var trip: Trip?

    @Relationship(deleteRule: .cascade)
    var activities: [TripActivity]?

    init(
        dayNumber: Int = 1,
        date: Date? = nil,
        label: String? = nil,
        trip: Trip? = nil
    ) {
        self.dayNumber = dayNumber
        self.date = date
        self.label = label
        self.trip = trip
    }

    // MARK: Computed

    var sortedActivities: [TripActivity] {
        (self.activities ?? []).sorted { lhs, rhs in
            switch (lhs.time, rhs.time) {
            case let (l?, r?): l < r
            case (nil, .some): false
            case (.some, nil): true
            case (nil, nil): lhs.name < rhs.name
            }
        }
    }

    var displayLabel: String {
        if let label, !label.trimmingCharacters(in: .whitespaces).isEmpty {
            return label
        }
        return "Day \(self.dayNumber)"
    }

    var dateLabel: String? {
        guard let date else { return nil }
        return Self.dayDateFormatter.string(from: date)
    }

    var activityCount: Int {
        (self.activities ?? []).count
    }

    var completedActivityCount: Int {
        self.sortedActivities.count(where: { $0.activityStatus == .done })
    }

    var pendingActivityCount: Int {
        self.sortedActivities.count(where: { $0.activityStatus == .planned })
    }

    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}

// MARK: - TripActivity

/// A single activity within a trip day (restaurant visit, attraction, flight, etc.).
@Model
final class TripActivity {
    var name: String = ""
    var time: Date?
    var typeRaw: String = ActivityType.other.rawValue
    var statusRaw: String = ActivityStatus.planned.rawValue
    var notes: String?
    var location: String?

    var day: TripDay?

    init(
        name: String,
        time: Date? = nil,
        type: ActivityType = .other,
        status: ActivityStatus = .planned,
        notes: String? = nil,
        location: String? = nil,
        day: TripDay? = nil
    ) {
        self.name = name
        self.time = time
        self.typeRaw = type.rawValue
        self.statusRaw = status.rawValue
        self.notes = notes
        self.location = location
        self.day = day
    }

    // MARK: Computed

    var type: ActivityType {
        get { ActivityType(rawValue: self.typeRaw) ?? .other }
        set { self.typeRaw = newValue.rawValue }
    }

    var activityStatus: ActivityStatus {
        get { ActivityStatus(rawValue: self.statusRaw) ?? .planned }
        set { self.statusRaw = newValue.rawValue }
    }

    var timeLabel: String? {
        guard let time else { return nil }
        return Self.timeFormatter.string(from: time)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - TripStatus

enum TripStatus: String, CaseIterable, Identifiable, Sendable {
    case upcoming
    case inProgress
    case completed

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .upcoming: "Upcoming"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        }
    }

    var systemImage: String {
        switch self {
        case .upcoming: "calendar"
        case .inProgress: "airplane"
        case .completed: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: AppColors.info
        case .inProgress: AppColors.gold
        case .completed: AppColors.safe
        }
    }

    /// Display order for section grouping (in-progress first).
    var sortOrder: Int {
        switch self {
        case .inProgress: 0
        case .upcoming: 1
        case .completed: 2
        }
    }
}

// MARK: - ActivityType

enum ActivityType: String, CaseIterable, Identifiable, Sendable {
    case accommodation
    case attraction
    case flight
    case food
    case nightlife
    case other
    case shopping
    case transport
    case wakeUp

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .food: "Food"
        case .attraction: "Attraction"
        case .transport: "Transport"
        case .accommodation: "Accommodation"
        case .shopping: "Shopping"
        case .nightlife: "Nightlife"
        case .wakeUp: "Wake Up"
        case .flight: "Flight"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .food: "fork.knife"
        case .attraction: "star.fill"
        case .transport: "car.fill"
        case .accommodation: "bed.double.fill"
        case .shopping: "bag.fill"
        case .nightlife: "moon.stars.fill"
        case .wakeUp: "alarm.fill"
        case .flight: "airplane"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: AppColors.coral
        case .attraction: AppColors.gold
        case .transport: AppColors.info
        case .accommodation: AppColors.violet
        case .shopping: AppColors.magenta
        case .nightlife: AppColors.violet
        case .wakeUp: AppColors.gold
        case .flight: AppColors.info
        case .other: AppColors.secondaryLabel
        }
    }
}

// MARK: - ActivityStatus

enum ActivityStatus: String, CaseIterable, Identifiable, Sendable {
    case planned
    case done
    case skipped

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .planned: "Planned"
        case .done: "Done"
        case .skipped: "Skipped"
        }
    }

    var systemImage: String {
        switch self {
        case .planned: "clock"
        case .done: "checkmark.circle.fill"
        case .skipped: "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .planned: AppColors.info
        case .done: AppColors.safe
        case .skipped: AppColors.secondaryLabel
        }
    }

    /// Cycles to the next status: planned → done → skipped → planned.
    var next: ActivityStatus {
        switch self {
        case .planned: .done
        case .done: .skipped
        case .skipped: .planned
        }
    }
}
