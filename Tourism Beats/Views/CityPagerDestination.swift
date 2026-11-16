import CoreGraphics
import Synchronization

// MARK: - CityPagerDestination

/// Where the city pager's current swipe will come to rest.
///
/// Written as a swipe ends, from the scroll target behavior, which isn't
/// isolated to the main actor, and read when the glide begins. It's a plain
/// locked reference rather than view state, so recording it never redraws
/// the pager.
final class CityPagerDestination: Sendable {
    private let storedOffset = Mutex<CGFloat?>(nil)

    /// Records the resting content offset the swipe chose.
    func record(_ offset: CGFloat) {
        self.storedOffset.withLock { $0 = offset }
    }

    /// The resting offset recorded since the last call, if a swipe is ending.
    func take() -> CGFloat? {
        self.storedOffset.withLock { offset in
            defer { offset = nil }
            return offset
        }
    }
}
