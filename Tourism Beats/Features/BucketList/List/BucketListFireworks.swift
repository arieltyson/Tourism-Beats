import SwiftUI

// MARK: - BucketListFireworks

/// Fireworks bursting over the empty bucket list.
///
/// With Reduce Motion on, a still fireworks symbol stands in for the show.
/// While the app is in the background, the show pauses.
struct BucketListFireworks: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var side = BucketListTokens.fireworksSide
    @Environment(\.scenePhase) private var scenePhase

    private static let palette = [AppColors.gold, AppColors.coral, AppColors.magenta]

    var body: some View {
        Group {
            if self.reduceMotion {
                Image(systemName: "fireworks")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(AppColors.gold, AppColors.coral)
                    .padding(self.side / 4)
            } else {
                TimelineView(.animation(paused: self.scenePhase != .active)) { context in
                    Canvas { canvas, size in
                        let halfWidth = min(size.width, size.height) / 2
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let time = context.date.timeIntervalSinceReferenceDate

                        func point(_ unit: CGPoint) -> CGPoint {
                            CGPoint(x: center.x + unit.x * halfWidth, y: center.y + unit.y * halfWidth)
                        }

                        for spark in FireworksShow.sparks(at: time) {
                            let color = Self.palette[spark.colorIndex]
                            let radius = spark.radius * halfWidth
                            let head = point(spark.position)

                            var trail = Path()
                            trail.move(to: point(spark.trailStart))
                            trail.addLine(to: head)
                            canvas.stroke(
                                trail,
                                with: .linearGradient(
                                    Gradient(colors: [color.opacity(0), color.opacity(spark.opacity)]),
                                    startPoint: point(spark.trailStart),
                                    endPoint: head
                                ),
                                style: StrokeStyle(lineWidth: radius, lineCap: .round)
                            )

                            canvas.fill(
                                Circle().path(in: CGRect(
                                    x: head.x - radius,
                                    y: head.y - radius,
                                    width: radius * 2,
                                    height: radius * 2
                                )),
                                with: .color(color.opacity(spark.opacity))
                            )
                        }
                    }
                }
            }
        }
        .frame(width: self.side, height: self.side)
        .accessibilityHidden(true)
    }
}
