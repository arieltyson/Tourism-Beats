import Foundation

// MARK: - OverpassAvailability

/// Remembers recent Overpass outages so queries skip the network while every
/// public instance is known to be failing.
actor OverpassAvailability {
    static let shared = OverpassAvailability()

    private let cooldown: Duration
    private let clock = ContinuousClock()
    private var unavailableUntil: ContinuousClock.Instant?

    init(cooldown: Duration = .seconds(5 * 60)) {
        self.cooldown = cooldown
    }

    func isAvailable() -> Bool {
        guard let unavailableUntil else { return true }
        return self.clock.now >= unavailableUntil
    }

    func recordOutage() {
        self.unavailableUntil = self.clock.now.advanced(by: self.cooldown)
    }

    func recordSuccess() {
        self.unavailableUntil = nil
    }
}
