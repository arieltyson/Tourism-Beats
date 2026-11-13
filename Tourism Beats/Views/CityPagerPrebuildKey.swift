// MARK: - CityPagerPrebuildKey

/// What decides whether the pager builds another page ahead of time: which
/// pages exist, and whether it's at rest. Any change cancels a pending build,
/// so a swipe never shares its frames with one.
struct CityPagerPrebuildKey: Equatable {
    let loadedPages: Set<Int>
    let settledPageIndex: Int
    let isAtRest: Bool
}
