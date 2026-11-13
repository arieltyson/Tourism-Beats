// MARK: - CityPagerLoading

/// Decides which city pages to build, and when.
///
/// Building a page lays it out and starts its loading, which is too much to
/// do while pages are moving. So pages are built while the pager is at rest:
/// the page it settled on and the pages up to two away, so even two swipes in
/// quick succession, with no rest between, land on a page that's ready. The
/// pages beyond are then built one at a time while the pager stays at rest,
/// so even a run of swipes finds every page ready. A built page is kept, so
/// going back never builds it again.
enum CityPagerLoading {
    /// How many pages either side of the settled one are built.
    static let reach = 2

    /// The rest between building one page ahead of time and the next, so each
    /// page's first layout and loading have the main thread to themselves.
    static let prebuildPause: Duration = .milliseconds(250)

    /// The pages to have built while the pager rests on `index`.
    static func pages(around index: Int, pageCount: Int) -> Set<Int> {
        let pages = (index - Self.reach) ... (index + Self.reach)
        return Set(pages.clamped(to: 0 ... max(pageCount - 1, 0)))
    }

    /// The unbuilt page to build next while the pager rests on `index`: the
    /// closest one, and of two as close, the one further on. `nil` once every
    /// page is built.
    static func nextPageToPrebuild(around index: Int, loadedPages: Set<Int>, pageCount: Int) -> Int? {
        (0 ..< pageCount)
            .filter { !loadedPages.contains($0) }
            .min { lhs, rhs in
                let (lhsDistance, rhsDistance) = (abs(lhs - index), abs(rhs - index))
                return lhsDistance == rhsDistance ? lhs > rhs : lhsDistance < rhsDistance
            }
    }
}
