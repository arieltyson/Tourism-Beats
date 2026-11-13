// MARK: - TripLength

/// How long a trip runs: its days, and the nights a stay covers between them.
struct TripLength: Hashable, Sendable {
    let days: Int

    init(days: Int) {
        self.days = max(days, 1)
    }

    /// One night fewer than its days, though even a day trip may book one.
    var nights: Int {
        max(self.days - 1, 1)
    }
}
