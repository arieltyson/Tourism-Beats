import SwiftUI

/// A small state value used as the `.sensoryFeedback` trigger in SwiftUI.
///
/// `fireCount` increments on every call to `fire(_:)` so repeated events
/// still produce haptics when the same event type occurs back-to-back.
struct HapticTrigger: Equatable, Sendable {
    /// Navigation and exploration events that should produce tactile feedback.
    enum Event: Sendable, Equatable {
        case pageChange
        case citySelect
        case searchOpen
        case searchClose
        case advisoryExpand
        case musicPlay
    }

    /// Internal semantic mapping used by feedback conversion.
    enum FeedbackStyle: Sendable, Equatable {
        case impactLight
        case impactSoft
        case impactMedium
        case impactHeavy
        case selection
    }

    /// The most recently fired event.
    private(set) var event: Event?

    /// Incremented for every event so two consecutive identical events are
    /// still treated as distinct trigger values by SwiftUI.
    private var fireCount = 0

    /// Semantic style derived from the current event.
    var style: FeedbackStyle {
        switch self.event {
        case .pageChange: .impactMedium
        case .citySelect: .impactLight
        case .searchOpen: .impactSoft
        case .searchClose: .impactSoft
        case .advisoryExpand: .selection
        case .musicPlay: .impactHeavy
        case .none: .impactLight
        }
    }

    /// SwiftUI feedback style used by `.sensoryFeedback`.
    var feedback: SensoryFeedback {
        switch self.style {
        case .impactLight: .impact(weight: .light)
        case .impactSoft: .impact(flexibility: .soft)
        case .impactMedium: .impact(weight: .medium)
        case .impactHeavy: .impact(weight: .heavy)
        case .selection: .selection
        }
    }

    /// Registers a new event and updates the trigger value.
    mutating func fire(_ event: Event) {
        self.event = event
        self.fireCount += 1
    }
}
