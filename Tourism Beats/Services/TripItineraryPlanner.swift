import CoreLocation
import Foundation

// MARK: - TripActivitySuggestion

/// A place the itinerary planner proposes adding to a trip day.
struct TripActivitySuggestion: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let type: ActivityType
    let slot: TripItineraryPlanner.Slot
    let location: String?
    let notes: String?
    let sourceName: String
}

// MARK: - TripItineraryPlanner

/// Spreads a city's ranked sights and restaurants across trip days.
///
/// Each day follows a light template: a morning sight, lunch, an afternoon
/// sight, and dinner. Slots a day already covers are left alone, travel time
/// around arrival and departure flights is kept free, and places already in
/// the trip are never suggested again. A day's second sight and its meals are
/// chosen near its first sight so the day stays easy to get around.
enum TripItineraryPlanner {
    // MARK: Slot

    enum Slot: Int, CaseIterable, Comparable, Sendable {
        case morning
        case lunch
        case afternoon
        case dinner

        var hour: Int {
            switch self {
            case .morning: 9
            case .lunch: 12
            case .afternoon: 15
            case .dinner: 19
            }
        }

        var minute: Int {
            switch self {
            case .morning: 30
            case .lunch: 30
            case .afternoon: 0
            case .dinner: 0
            }
        }

        var isMeal: Bool {
            switch self {
            case .dinner, .lunch: true
            case .afternoon, .morning: false
            }
        }

        var label: String {
            switch self {
            case .morning: "Morning"
            case .lunch: "Lunch"
            case .afternoon: "Afternoon"
            case .dinner: "Dinner"
            }
        }

        /// Minutes after midnight at which this slot's window ends.
        ///
        /// Windows are contiguous, so every time of day belongs to exactly one slot.
        private var windowEndMinute: Int {
            switch self {
            case .morning: 11 * 60 + 30
            case .lunch: 14 * 60 + 30
            case .afternoon: 17 * 60 + 30
            case .dinner: 24 * 60
            }
        }

        static func containing(minuteOfDay: Int) -> Slot {
            self.allCases.first { minuteOfDay < $0.windowEndMinute } ?? .dinner
        }

        static func < (lhs: Slot, rhs: Slot) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: Inputs

    /// What the planner needs to know about an activity already on a day.
    struct ExistingActivity: Sendable {
        let type: ActivityType
        /// Minutes after midnight, or `nil` when the activity has no time.
        let minuteOfDay: Int?
    }

    /// A trip day the planner may add suggestions to.
    struct Day: Sendable {
        let existingActivities: [ExistingActivity]
        let isFirstDayOfTrip: Bool
        let isLastDayOfTrip: Bool
    }

    // MARK: Planning

    /// Proposes suggestions for each day, returned in the same order as `days`.
    ///
    /// - Parameters:
    ///   - activities: Ranked sights and experiences, best first.
    ///   - restaurants: Ranked restaurants, best first.
    ///   - excludedPlaceNames: Names already planned anywhere in the trip.
    static func plan(
        days: [Day],
        activities: [CityActivity],
        restaurants: [CityRestaurant],
        excludedPlaceNames: some Sequence<String>
    ) -> [[TripActivitySuggestion]] {
        let excludedKeys = excludedPlaceNames.map(CityActivityRanking.placeKey(for:))
        var sightPool = Self.uniqueCandidates(
            activities.map(Candidate.init(activity:)),
            excluding: excludedKeys
        )
        var restaurantPool = Self.uniqueCandidates(
            restaurants.map(Candidate.init(restaurant:)),
            excluding: excludedKeys + sightPool.map(\.key)
        )

        let openSlotsByDay = days.map(Self.openSlots(for:))
        var assignments = Array(repeating: [Slot: Candidate](), count: days.count)

        // Give every day its first sight before any day gets a second one, so a
        // short pool spreads across the trip instead of front-loading day one.
        for round in 0 ..< 2 {
            for dayIndex in days.indices {
                let openSightSlots = openSlotsByDay[dayIndex].filter { !$0.isMeal }
                guard round < openSightSlots.count else { continue }

                let anchor = assignments[dayIndex].values.first?.coordinate
                guard let candidate = Self.takeCandidate(nearest: anchor, from: &sightPool) else {
                    break
                }
                assignments[dayIndex][openSightSlots[round]] = candidate
            }
        }

        for mealSlot in Slot.allCases where mealSlot.isMeal {
            for dayIndex in days.indices where openSlotsByDay[dayIndex].contains(mealSlot) {
                let anchor = Self.centroid(of: assignments[dayIndex].values.compactMap(\.coordinate))
                guard let candidate = Self.takeCandidate(nearest: anchor, from: &restaurantPool) else {
                    break
                }
                assignments[dayIndex][mealSlot] = candidate
            }
        }

        return assignments.enumerated().map { dayIndex, assignment in
            assignment
                .sorted { $0.key < $1.key }
                .map { slot, candidate in
                    TripActivitySuggestion(
                        id: "\(dayIndex)-\(slot.rawValue)-\(candidate.id)",
                        name: candidate.name,
                        type: candidate.type,
                        slot: slot,
                        location: candidate.location,
                        notes: candidate.notes,
                        sourceName: candidate.sourceName
                    )
                }
        }
    }

    /// The template slots a day still has free.
    static func openSlots(for day: Day) -> [Slot] {
        var open = Set(Slot.allCases)

        for activity in day.existingActivities {
            switch activity.type {
            case .wakeUp:
                continue
            case .flight:
                open.subtract(Self.slotsBlocked(byFlight: activity, on: day))
            case .food:
                if let minuteOfDay = activity.minuteOfDay {
                    let slot = Slot.containing(minuteOfDay: minuteOfDay)
                    // Breakfast does not replace the morning sight.
                    if slot.isMeal {
                        open.remove(slot)
                    }
                } else if let meal = Slot.allCases.first(where: { $0.isMeal && open.contains($0) }) {
                    open.remove(meal)
                }
            case .accommodation:
                if let minuteOfDay = activity.minuteOfDay {
                    open.remove(Slot.containing(minuteOfDay: minuteOfDay))
                }
            case .attraction, .nightlife, .other, .shopping, .transport:
                if let minuteOfDay = activity.minuteOfDay {
                    open.remove(Slot.containing(minuteOfDay: minuteOfDay))
                } else if let sight = Slot.allCases.first(where: { !$0.isMeal && open.contains($0) }) {
                    open.remove(sight)
                }
            }
        }

        return open.sorted()
    }

    /// Arrival flights block the slots before landing, departures the slots
    /// after take-off. Without a time, only dinner (arrival) or the morning
    /// (departure) is assumed to be free, and a mid-trip flight takes the
    /// morning like any other untimed plan.
    private static func slotsBlocked(byFlight flight: ExistingActivity, on day: Day) -> Set<Slot> {
        guard let minuteOfDay = flight.minuteOfDay else {
            var blocked = Set<Slot>()
            if day.isFirstDayOfTrip {
                blocked.formUnion([.morning, .lunch, .afternoon])
            }
            if day.isLastDayOfTrip {
                blocked.formUnion([.lunch, .afternoon, .dinner])
            }
            return blocked.isEmpty ? [.morning] : blocked
        }

        let flightSlot = Slot.containing(minuteOfDay: minuteOfDay)
        var blocked: Set<Slot> = [flightSlot]
        if day.isFirstDayOfTrip {
            blocked.formUnion(Slot.allCases.filter { $0 < flightSlot })
        }
        if day.isLastDayOfTrip {
            blocked.formUnion(Slot.allCases.filter { $0 > flightSlot })
        }
        return blocked
    }
}

// MARK: - Candidate Selection

extension TripItineraryPlanner {
    private struct Candidate: Sendable {
        let id: String
        let key: String
        let name: String
        let type: ActivityType
        let coordinate: CLLocationCoordinate2D?
        let location: String?
        let notes: String?
        let sourceName: String

        init(activity: CityActivity) {
            self.id = activity.id
            self.key = CityActivityRanking.placeKey(for: activity.name)
            self.name = activity.name
            self.type = .attraction
            self.coordinate = TripItineraryPlanner.coordinate(
                latitude: activity.latitude,
                longitude: activity.longitude
            )
            self.location = activity.locationSummary
            self.notes = TripItineraryPlanner.joinedNote([
                TripItineraryPlanner.genericLabels.contains(activity.category) ? nil : activity.category,
                activity.timingTip
            ])
            self.sourceName = activity.sourceName
        }

        init(restaurant: CityRestaurant) {
            self.id = restaurant.id
            self.key = CityActivityRanking.placeKey(for: restaurant.name)
            self.name = restaurant.name
            self.type = .food
            self.coordinate = TripItineraryPlanner.coordinate(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            )
            self.location = restaurant.address
            self.notes = TripItineraryPlanner.joinedNote([
                restaurant.cuisine.flatMap { TripItineraryPlanner.genericLabels.contains($0) ? nil : $0 },
                restaurant.dietarySummary
            ])
            self.sourceName = restaurant.sourceName
        }
    }

    /// Category names that only repeat the activity type, so they are not
    /// worth showing as a note.
    private static let genericLabels: Set<String> = ["Attraction", "Experience", "Restaurant"]

    /// Whether two place keys name the same place. Besides exact matches, a
    /// name of two or more words inside another counts, so "Fort George"
    /// matches "Fort George lookout" and "Lunch at Veni Mange" matches "Veni Mange".
    static func isSamePlace(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs != rhs else { return true }

        let (shorter, longer) = lhs.count < rhs.count ? (lhs, rhs) : (rhs, lhs)
        guard shorter.split(separator: " ").count >= 2 else { return false }
        return " \(longer) ".contains(" \(shorter) ")
    }

    private static func uniqueCandidates(
        _ candidates: [Candidate],
        excluding excludedKeys: [String]
    ) -> [Candidate] {
        var seenKeys = excludedKeys
        return candidates.filter { candidate in
            guard !candidate.key.isEmpty,
                  !seenKeys.contains(where: { Self.isSamePlace($0, candidate.key) })
            else {
                return false
            }

            seenKeys.append(candidate.key)
            return true
        }
    }

    /// Removes and returns the closest candidate to `anchor`, or the
    /// best-ranked one when there is no anchor or no candidate has coordinates.
    private static func takeCandidate(
        nearest anchor: CLLocationCoordinate2D?,
        from pool: inout [Candidate]
    ) -> Candidate? {
        guard !pool.isEmpty else { return nil }

        guard let anchor else { return pool.removeFirst() }

        let anchorLocation = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
        let nearestIndex = pool.indices
            .compactMap { index -> (index: Int, distance: CLLocationDistance)? in
                guard let coordinate = pool[index].coordinate else { return nil }
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                return (index, location.distance(from: anchorLocation))
            }
            .min { $0.distance < $1.distance }?
            .index

        return pool.remove(at: nearestIndex ?? pool.startIndex)
    }

    private static func centroid(of coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }
        let count = Double(coordinates.count)
        return CLLocationCoordinate2D(
            latitude: coordinates.map(\.latitude).reduce(0, +) / count,
            longitude: coordinates.map(\.longitude).reduce(0, +) / count
        )
    }

    private static func coordinate(latitude: Double?, longitude: Double?) -> CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }

    private static func joinedNote(_ parts: [String?]) -> String? {
        let note = parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        return note.isEmpty ? nil : note
    }
}
