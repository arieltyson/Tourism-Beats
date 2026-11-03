import SwiftUI

/// A timeline that ticks on each whole second while running and not at all
/// while paused, so a clock off screen costs nothing.
struct OnScreenTicks: TimelineSchedule {
    let isPaused: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> UnfoldSequence<Date, (Date?, Bool)> {
        let firstSecond = Date(timeIntervalSinceReferenceDate: startDate.timeIntervalSinceReferenceDate.rounded(.down))
        // While paused, the one entry draws the clock as it stands.
        return sequence(state: (Date?.some(firstSecond), isPaused)) { state in
            guard let next = state.0 else { return nil }
            state.0 = state.1 ? nil : next.addingTimeInterval(1)
            return next
        }
    }
}
