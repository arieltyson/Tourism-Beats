import SwiftUI

// MARK: - WalkingStickman

/// An animated stickman inspired by Apple Fitness's walking figure.
///
/// Uses `TimelineView` with `Canvas` for smooth, sine-wave-driven
/// skeletal animation. Automatically falls back to a static mid-stride
/// pose when Reduce Motion is enabled.
struct WalkingStickman: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Overall height of the stickman figure.
    let height: CGFloat

    /// Color for the figure's limbs, torso, and head.
    var color: Color = .green

    /// Duration of one full walk cycle (two steps) in seconds.
    private let cycleDuration: Double = 1.8

    var body: some View {
        if self.reduceMotion {
            self.stickmanCanvas(phase: .pi / 4)
        } else {
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSinceReferenceDate
                let phase = elapsed * 2 * .pi / self.cycleDuration
                self.stickmanCanvas(phase: phase)
            }
        }
    }

    private func stickmanCanvas(phase: Double) -> some View {
        Canvas { context, size in
            self.drawStickman(in: &context, size: size, phase: phase)
        }
        .frame(width: self.height * 0.65, height: self.height)
        .accessibilityLabel("Walking figure")
        .accessibilityHidden(true)
    }

    // MARK: - Drawing

    private func drawStickman(
        in ctx: inout GraphicsContext,
        size: CGSize,
        phase: Double
    ) {
        let scale = self.height / 52
        let style = StrokeStyle(
            lineWidth: 4.0 * scale,
            lineCap: .round,
            lineJoin: .round
        )

        // Vertical body bob (two bobs per cycle)
        let bob = 1.0 * scale * abs(sin(phase))

        // Key positions
        let headRadius = 2.8 * scale
        let centerX = size.width / 2
        let headCenterY = headRadius + 2 * scale - bob
        let shoulderY = headCenterY + headRadius + 1.5 * scale
        let hipY = shoulderY + 12.0 * scale
        let skeleton = Skeleton(
            hip: CGPoint(x: centerX, y: hipY),
            shoulder: CGPoint(x: centerX, y: shoulderY + 2 * scale),
            scale: scale
        )

        // The right side leads on the first half of the cycle; the other
        // side is half a cycle behind.
        let rightSide = skeleton.limbs(phase: phase)
        let leftSide = skeleton.limbs(phase: phase + .pi)
        let rightForward = sin(phase) > 0
        let (farSide, nearSide) = rightForward ? (leftSide, rightSide) : (rightSide, leftSide)

        // Far side first, dimmed, so the near side reads in front of it.
        for limb in farSide {
            self.draw(limb, in: &ctx, style: style, color: self.color.opacity(0.55))
        }

        var torsoPath = Path()
        torsoPath.move(to: CGPoint(x: centerX, y: shoulderY))
        torsoPath.addLine(to: CGPoint(x: centerX, y: hipY))
        ctx.stroke(torsoPath, with: .color(self.color), style: style)

        let headRect = CGRect(
            x: centerX - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        )
        ctx.fill(Circle().path(in: headRect), with: .color(self.color))

        for limb in nearSide {
            self.draw(limb, in: &ctx, style: style, color: self.color)
        }
    }

    private func draw(
        _ limb: Limb,
        in ctx: inout GraphicsContext,
        style: StrokeStyle,
        color: Color
    ) {
        let upperRadians = limb.angle * .pi / 180
        let lowerRadians = (limb.angle + limb.lowerBend) * .pi / 180

        let joint = CGPoint(
            x: limb.origin.x + limb.upperLength * sin(upperRadians),
            y: limb.origin.y + limb.upperLength * cos(upperRadians)
        )
        let end = CGPoint(
            x: joint.x + limb.lowerLength * sin(lowerRadians),
            y: joint.y + limb.lowerLength * cos(lowerRadians)
        )

        var path = Path()
        path.move(to: limb.origin)
        path.addLine(to: joint)
        path.addLine(to: end)
        ctx.stroke(path, with: .color(color), style: style)
    }
}

// MARK: - Skeleton

/// Stocky, compact proportions and the walk cycle's joint angles.
///
/// Angles are degrees from vertical, positive forward.
private struct Skeleton {
    let hip: CGPoint
    let shoulder: CGPoint
    let scale: CGFloat

    /// The leg and arm for one side of the body at `phase`.
    func limbs(phase: Double) -> [Limb] {
        // Knee bend peaks during mid-forward-swing; arms oppose legs, and the
        // elbow bends more as the arm swings backward.
        let leg = Limb(
            origin: self.hip,
            upperLength: 9.0 * self.scale,
            lowerLength: 8.0 * self.scale,
            angle: 25 * sin(phase),
            lowerBend: -30 * max(0, cos(phase - .pi / 4))
        )
        let arm = Limb(
            origin: self.shoulder,
            upperLength: 7.0 * self.scale,
            lowerLength: 5.5 * self.scale,
            angle: -22 * sin(phase),
            lowerBend: 12 + 12 * max(0, sin(phase))
        )
        return [leg, arm]
    }
}

// MARK: - Limb

/// Two jointed segments: a thigh and calf, or an upper arm and forearm.
private struct Limb {
    let origin: CGPoint
    let upperLength: CGFloat
    let lowerLength: CGFloat
    let angle: Double
    /// Added to `angle` for the lower segment: negative bends a knee back,
    /// positive bends an elbow forward.
    let lowerBend: Double
}
