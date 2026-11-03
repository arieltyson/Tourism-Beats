import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

struct OnScreenTicksTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000.4)

    @Test func runningTicksLandOnWholeSeconds() {
        let ticks = Array(OnScreenTicks(isPaused: false).entries(from: start, mode: .normal).prefix(3))
        #expect(ticks.map(\.timeIntervalSinceReferenceDate) == [1_000, 1_001, 1_002])
    }

    /// Paused, the clock draws once as it stands and then asks for nothing.
    @Test func pausedTicksStopAfterOne() {
        let ticks = Array(OnScreenTicks(isPaused: true).entries(from: start, mode: .normal).prefix(3))
        #expect(ticks.map(\.timeIntervalSinceReferenceDate) == [1_000])
    }
}
