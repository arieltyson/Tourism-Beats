import CoreGraphics
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - FireworksShowTests

struct FireworksShowTests {
    /// The first burst has just begun: its sparks sit at its center, bright.
    @Test func aBurstStartsAtItsCenter() throws {
        let sparks = FireworksShow.sparks(at: 0)
        let first = try #require(sparks.first)

        #expect(sparks.count >= BucketListTokens.sparksPerBurst)
        #expect(abs(first.position.x) < 0.001)
        #expect(abs(first.position.y + 0.2) < 0.001)
        #expect(first.opacity == 1)
    }

    /// Every spark stays on the canvas and fades rather than popping out.
    @Test(arguments: stride(from: 0.0, to: BucketListTokens.fireworksPeriod, by: 0.1).map(\.self))
    func sparksStayOnTheCanvas(time: TimeInterval) {
        for spark in FireworksShow.sparks(at: time) {
            #expect(abs(spark.position.x) + spark.radius <= 1)
            #expect(abs(spark.position.y) + spark.radius <= 1)
            #expect((0 ... 1).contains(spark.opacity))
        }
    }

    @Test func theShowRepeats() {
        let time: TimeInterval = 0.5
        let now = FireworksShow.sparks(at: time)
        let later = FireworksShow.sparks(at: time + BucketListTokens.fireworksPeriod * 3)

        #expect(now.count == later.count)
        for (spark, repeated) in zip(now, later) {
            #expect(abs(spark.position.x - repeated.position.x) < 0.0001)
            #expect(abs(spark.position.y - repeated.position.y) < 0.0001)
            #expect(abs(spark.opacity - repeated.opacity) < 0.0001)
        }
    }
}
