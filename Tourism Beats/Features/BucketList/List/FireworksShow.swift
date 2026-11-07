import CoreGraphics
import Foundation

// MARK: - FireworksShow

/// Where every spark of the empty state's fireworks is at a moment.
///
/// Three bursts bloom one after another across the sky and repeat. Each is
/// a ring of sparks that flies out fast, slows, falls a little, and fades.
/// Positions are in a unit space centered on the canvas, where 1 is half
/// its width, so the drawing scales to any size.
enum FireworksShow {
    struct Spark: Equatable {
        /// The spark's center, in unit space.
        let position: CGPoint
        /// Where the spark's trail starts, back along its path.
        let trailStart: CGPoint
        /// The spark's radius, in unit space.
        let radius: CGFloat
        let opacity: Double
        /// Which of the palette's colors the spark's burst uses.
        let colorIndex: Int
    }

    private struct Burst {
        let center: CGPoint
        let delay: TimeInterval
        let colorIndex: Int
    }

    private static let bursts = [
        Burst(center: CGPoint(x: 0, y: -0.2), delay: 0, colorIndex: 0),
        Burst(center: CGPoint(x: -0.4, y: 0.15), delay: 0.8, colorIndex: 1),
        Burst(center: CGPoint(x: 0.4, y: 0.1), delay: 1.6, colorIndex: 2),
    ]

    /// The sparks in the sky at a moment of the show.
    static func sparks(at time: TimeInterval) -> [Spark] {
        let showTime = time.truncatingRemainder(dividingBy: BucketListTokens.fireworksPeriod)

        return self.bursts.flatMap { burst -> [Spark] in
            // A burst that started near the end of the last show is still fading.
            var age = showTime - burst.delay
            if age < 0 { age += BucketListTokens.fireworksPeriod }
            guard age < BucketListTokens.burstLifetime else { return [] }
            return self.sparks(of: burst, progress: age / BucketListTokens.burstLifetime)
        }
    }

    /// The sparks of one burst, `progress` of the way through its life.
    private static func sparks(of burst: Burst, progress: Double) -> [Spark] {
        let opacity = 1 - progress * progress
        let radius = BucketListTokens.sparkRadius * (1 - progress / 2)
        let trailProgress = max(progress - BucketListTokens.trailLag, 0)

        return (0 ..< BucketListTokens.sparksPerBurst).map { index in
            let angle = Double(index) / Double(BucketListTokens.sparksPerBurst) * 2 * .pi
            let ring = index.isMultiple(of: 2) ? 1 : BucketListTokens.innerRingReach
            return Spark(
                position: self.point(of: burst, angle: angle, ring: ring, progress: progress),
                trailStart: self.point(of: burst, angle: angle, ring: ring, progress: trailProgress),
                radius: radius,
                opacity: opacity,
                colorIndex: burst.colorIndex
            )
        }
    }

    /// Where a spark is along its path: out fast then slower, as an ease out,
    /// and falling a little as it goes.
    private static func point(of burst: Burst, angle: Double, ring: CGFloat, progress: Double) -> CGPoint {
        let spread = 1 - pow(1 - progress, 3)
        let reach = BucketListTokens.sparkReach * ring * spread
        let fall = BucketListTokens.sparkFall * progress * progress
        return CGPoint(
            x: burst.center.x + reach * cos(angle),
            y: burst.center.y + reach * sin(angle) + fall
        )
    }
}
