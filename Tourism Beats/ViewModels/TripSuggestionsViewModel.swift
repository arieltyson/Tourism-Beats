import Foundation
import Observation
import SwiftData

// MARK: - TripSuggestionsViewModel

/// Loads a city's activity and restaurant guides and turns them into
/// reviewable, per-day suggestions for a trip itinerary.
@MainActor
@Observable
final class TripSuggestionsViewModel {
    // MARK: Types

    /// Which part of the itinerary the user asked to fill.
    enum Scope {
        case trip
        case day(TripDay)
    }

    /// Suggestions proposed for one itinerary day.
    struct DaySuggestions: Identifiable {
        let day: TripDay
        let suggestions: [TripActivitySuggestion]

        var id: PersistentIdentifier { self.day.persistentModelID }
    }

    enum State {
        case loading
        case loaded([DaySuggestions])
        case unavailable(title: String, message: String, canRetry: Bool)
    }

    // MARK: State

    private(set) var state: State = .loading
    private(set) var coverageNote: String?
    var selectedSuggestionIDs: Set<String> = []

    let city: CityModel

    @ObservationIgnored private let trip: Trip
    @ObservationIgnored private let scope: Scope
    @ObservationIgnored private let activityService: any CityActivityProviding
    @ObservationIgnored private let restaurantService: any CityRestaurantProviding
    @ObservationIgnored private let calendar: Calendar

    init(
        trip: Trip,
        city: CityModel,
        scope: Scope,
        activityService: any CityActivityProviding = CityActivityService.shared,
        restaurantService: any CityRestaurantProviding = CityRestaurantService.shared,
        calendar: Calendar = .current
    ) {
        self.trip = trip
        self.city = city
        self.scope = scope
        self.activityService = activityService
        self.restaurantService = restaurantService
        self.calendar = calendar
    }

    // MARK: Derived

    var title: String {
        switch self.scope {
        case .trip:
            "Suggested Plan"
        case let .day(day):
            "Ideas for \(day.displayLabel)"
        }
    }

    var selectedCount: Int {
        self.selectedSuggestionIDs.count
    }

    var addButtonTitle: String {
        switch self.selectedCount {
        case 0: "Add"
        case 1: "Add 1 Activity"
        default: "Add \(self.selectedCount.formatted(.number)) Activities"
        }
    }

    func isSelected(_ suggestion: TripActivitySuggestion) -> Bool {
        self.selectedSuggestionIDs.contains(suggestion.id)
    }

    func toggle(_ suggestion: TripActivitySuggestion) {
        if !self.selectedSuggestionIDs.insert(suggestion.id).inserted {
            self.selectedSuggestionIDs.remove(suggestion.id)
        }
    }

    // MARK: Loading

    func load() async {
        self.state = .loading
        self.coverageNote = nil

        let targetDays = self.targetDays
        let planningDays = targetDays.map(self.planningDay(for:))
        let openDayCount = planningDays.count { !TripItineraryPlanner.openSlots(for: $0).isEmpty }

        guard openDayCount > 0 else {
            self.state = .unavailable(
                title: "Already Planned",
                message: self.fullyPlannedMessage,
                canRetry: false
            )
            return
        }

        async let fetchedActivities = self.activityService.activities(for: self.city)
        async let fetchedRestaurants = self.restaurantService.restaurants(for: self.city)
        let (activities, restaurants) = await (fetchedActivities, fetchedRestaurants)

        guard !activities.isEmpty || !restaurants.isEmpty else {
            self.state = .unavailable(
                title: "Guide Unavailable",
                message: "Tourism Beats couldn't load the \(self.city.name) guide right now. "
                    + "Check your connection and try again.",
                canRetry: true
            )
            return
        }

        let plan = TripItineraryPlanner.plan(
            days: planningDays,
            activities: activities,
            restaurants: restaurants,
            excludedPlaceNames: self.trip.sortedDays.flatMap { $0.sortedActivities.map(\.name) }
        )
        let daySuggestions = zip(targetDays, plan)
            .filter { !$1.isEmpty }
            .map { DaySuggestions(day: $0, suggestions: $1) }

        guard !daySuggestions.isEmpty else {
            self.state = .unavailable(
                title: "No New Places",
                message: "Your trip already includes every top place in the \(self.city.name) guide. "
                    + "Add your own plans with Add Activity.",
                canRetry: false
            )
            return
        }

        if daySuggestions.count < openDayCount {
            self.coverageNote = "The \(self.city.name) guide had enough new places for "
                + "\(daySuggestions.count.formatted(.number)) of \(openDayCount.formatted(.number)) "
                + "open days. Use Add Activity to plan the rest your way."
        }

        self.selectedSuggestionIDs = Set(daySuggestions.flatMap { $0.suggestions.map(\.id) })
        self.state = .loaded(daySuggestions)
    }

    // MARK: Applying

    /// Adds the selected suggestions to their days and saves.
    ///
    /// - Returns: The number of activities added.
    @discardableResult
    func applySelection(in modelContext: ModelContext) throws -> Int {
        guard case let .loaded(daySuggestions) = self.state else { return 0 }

        var addedCount = 0
        for entry in daySuggestions {
            for suggestion in entry.suggestions where self.isSelected(suggestion) {
                modelContext.insert(
                    TripActivity(
                        name: suggestion.name,
                        time: self.time(for: suggestion.slot, on: entry.day),
                        type: suggestion.type,
                        notes: suggestion.notes,
                        location: suggestion.location,
                        day: entry.day
                    )
                )
                addedCount += 1
            }
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }

        return addedCount
    }

    // MARK: Private

    private var targetDays: [TripDay] {
        switch self.scope {
        case .trip:
            self.trip.sortedDays
        case let .day(day):
            [day]
        }
    }

    private var fullyPlannedMessage: String {
        switch self.scope {
        case .trip:
            "Every day of this trip already has its morning, lunch, afternoon, and dinner planned."
        case .day:
            "This day already has its morning, lunch, afternoon, and dinner planned."
        }
    }

    private func planningDay(for day: TripDay) -> TripItineraryPlanner.Day {
        let allDays = self.trip.sortedDays

        return TripItineraryPlanner.Day(
            existingActivities: day.sortedActivities.map { activity in
                TripItineraryPlanner.ExistingActivity(
                    type: activity.type,
                    minuteOfDay: activity.time.map(self.minuteOfDay(for:))
                )
            },
            isFirstDayOfTrip: allDays.first == day,
            isLastDayOfTrip: allDays.last == day
        )
    }

    private func minuteOfDay(for date: Date) -> Int {
        let components = self.calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func time(for slot: TripItineraryPlanner.Slot, on day: TripDay) -> Date? {
        self.calendar.date(
            bySettingHour: slot.hour,
            minute: slot.minute,
            second: 0,
            of: day.date ?? .now
        )
    }
}
