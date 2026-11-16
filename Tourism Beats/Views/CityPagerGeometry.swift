import CoreGraphics

// MARK: - CityPagerGeometry

/// Reads the city pager's position as a page.
enum CityPagerGeometry {
    /// The page mostly on screen at `offset`, so it changes as soon as a swipe
    /// crosses midway between two pages.
    static func page(atOffset offset: CGFloat, pageHeight: CGFloat, pageCount: Int) -> Int {
        guard pageHeight > 0, pageCount > 0 else { return 0 }
        let page = Int((offset / pageHeight).rounded())
        return min(max(page, 0), pageCount - 1)
    }
}
