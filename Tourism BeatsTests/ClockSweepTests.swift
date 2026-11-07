import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - ClockSweepTests

struct ClockSweepTests {
    private static let tick = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func sweepingHandsSetOffForTheNextTick() {
        #expect(ClockSweep.target(for: Self.tick, sweeps: true) == Self.tick.addingTimeInterval(1))
    }

    @Test func tickingHandsShowTheMomentItself() {
        #expect(ClockSweep.target(for: Self.tick, sweeps: false) == Self.tick)
    }

    @Test func consecutiveTicksSweepLinearly() {
        let animation = ClockSweep.animation(from: Self.tick, to: Self.tick.addingTimeInterval(1), sweeps: true)
        #expect(animation == .linear(duration: 1))
    }

    /// Coming back on screen, the hands jump to the time rather than spin to it.
    @Test(arguments: [0.0, 5.0, 600.0])
    func otherChangesJump(elapsed: TimeInterval) {
        #expect(ClockSweep.animation(from: Self.tick, to: Self.tick.addingTimeInterval(elapsed), sweeps: true) == nil)
    }

    @Test func reducedMotionNeverSweeps() {
        #expect(ClockSweep.animation(from: Self.tick, to: Self.tick.addingTimeInterval(1), sweeps: false) == nil)
    }
}
