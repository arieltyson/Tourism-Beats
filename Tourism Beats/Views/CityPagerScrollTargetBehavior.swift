import SwiftUI

// MARK: - CityPagerScrollTargetBehavior

/// Snaps the city pager to its pages one swipe at a time, and reports the page
/// each swipe will come to rest on.
///
/// The page is chosen by view-aligned snapping, which lands each swipe on the
/// next page even when a page's own content passes a swipe on. Knowing the page
/// lets the pager finish the glide itself, briskly, instead of drifting in.
struct CityPagerScrollTargetBehavior: ScrollTargetBehavior {
    let destination: CityPagerDestination

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        ViewAlignedScrollTargetBehavior(limitBehavior: .alwaysByOne).updateTarget(&target, context: context)

        self.destination.record(target.rect.minY)
    }
}
