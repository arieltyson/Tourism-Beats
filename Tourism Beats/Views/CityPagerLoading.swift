// MARK: - CityPagerLoading

/// Decides which city pages to build, and when.
///
/// Building a page lays it out and starts its loading, which is too much to
/// do while pages are moving. So pages are built while the pager is at rest:
/// the page it settled on and the pages up to two away, so even two swipes in
/// quick succession, with no rest between, land on a page that's ready. A
/// built page is kept, so going back never builds it again.
enum CityPagerLoading {
    /// How many pages either side of the settled one are built.
    static let reach = 2

    /// The pages to have built while the pager rests on `index`.
    static func pages(around index: Int, pageCount: Int) -> Set<Int> {
        let pages = (index - Self.reach) ... (index + Self.reach)
        return Set(pages.clamped(to: 0 ... max(pageCount - 1, 0)))
    }
}
