import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - ClockDialLayoutTests

struct ClockDialLayoutTests {
    private static let layout = ClockDialLayout(size: CGSize(width: 120, height: 120))

    /// Every corner of every numeral stays clear of the ticks, wide or narrow.
    @Test(arguments: 1 ... 12)
    func numeralsClearTheTicks(hour: Int) {
        let size = CGSize(width: hour >= 10 ? 18 : 10, height: 14)
        let center = Self.layout.numeralCenter(forHour: hour, size: size)

        for dx in [-size.width / 2, size.width / 2] {
            for dy in [-size.height / 2, size.height / 2] {
                let distance = hypot(center.x + dx, center.y + dy)
                #expect(distance <= Self.layout.numeralReach + 0.001)
            }
        }
    }

    /// Each numeral reaches the edge of its space, so the ring reads evenly.
    @Test(arguments: 1 ... 12)
    func numeralsSitAgainstTheirReach(hour: Int) {
        let size = CGSize(width: 12, height: 14)
        let center = Self.layout.numeralCenter(forHour: hour, size: size)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let corners = [
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y + halfHeight),
        ]
        let farthest = corners.map { hypot($0.x, $0.y) }.max() ?? 0

        #expect(abs(farthest - Self.layout.numeralReach) < 0.001)
    }

    @Test func twelveSitsStraightUp() {
        let center = Self.layout.numeralCenter(forHour: 12, size: CGSize(width: 16, height: 14))
        #expect(abs(center.x) < 0.001)
        #expect(center.y < 0)
    }

    @Test func ticksSitInsideTheRim() {
        #expect(Self.layout.tickOuterRadius < Self.layout.radius)
        #expect(Self.layout.tickInnerRadius < Self.layout.tickOuterRadius)
        #expect(Self.layout.numeralReach < Self.layout.tickInnerRadius)
    }
}
