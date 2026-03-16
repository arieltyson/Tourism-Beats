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
        let lineW = 4.0 * scale
        let style = StrokeStyle(
            lineWidth: lineW,
            lineCap: .round,
            lineJoin: .round
        )

        // Segment lengths — stocky, compact proportions
        let headR = 2.8 * scale
        let torso = 12.0 * scale
        let thigh = 9.0 * scale
        let calf = 8.0 * scale
        let upperArm = 7.0 * scale
        let forearm = 5.5 * scale

        // Vertical body bob (two bobs per cycle)
        let bob = 1.0 * scale * abs(sin(phase))

        // Key positions
        let cx = size.width / 2
        let headCY = headR + 2 * scale - bob
        let shoulderY = headCY + headR + 1.5 * scale
        let hipY = shoulderY + torso
        let armOriginY = shoulderY + 2 * scale

        // MARK: Joint angles (degrees from vertical, positive = forward)

        let rThighAng = 25 * sin(phase)
        let lThighAng = 25 * sin(phase + .pi)

        // Knee bend peaks during mid-forward-swing
        let rKnee = 30 * max(0, cos(phase - .pi / 4))
        let lKnee = 30 * max(0, cos(phase + .pi - .pi / 4))

        // Arms oppose legs
        let rArmAng = -22 * sin(phase)
        let lArmAng = -22 * sin(phase + .pi)

        // Elbow bends more when arm swings backward
        let rElbow = 12 + 12 * max(0, sin(phase))
        let lElbow = 12 + 12 * max(0, sin(phase + .pi))

        let hip = CGPoint(x: cx, y: hipY)
        let shoulder = CGPoint(x: cx, y: armOriginY)

        // Determine depth order — draw far side first
        let rightForward = sin(phase) > 0
        let dimColor = self.color.opacity(0.55)

        // MARK: Back limbs (far side, dimmed)

        if rightForward {
            self.drawLeg(
                in: &ctx, hip: hip, thigh: thigh, calf: calf,
                thighAngle: lThighAng, kneeBend: lKnee,
                style: style, color: dimColor
            )
            self.drawArm(
                in: &ctx, shoulder: shoulder,
                upper: upperArm, fore: forearm,
                armAngle: lArmAng, elbowBend: lElbow,
                style: style, color: dimColor
            )
        } else {
            self.drawLeg(
                in: &ctx, hip: hip, thigh: thigh, calf: calf,
                thighAngle: rThighAng, kneeBend: rKnee,
                style: style, color: dimColor
            )
            self.drawArm(
                in: &ctx, shoulder: shoulder,
                upper: upperArm, fore: forearm,
                armAngle: rArmAng, elbowBend: rElbow,
                style: style, color: dimColor
            )
        }

        // MARK: Torso

        var torsoPath = Path()
        torsoPath.move(to: CGPoint(x: cx, y: shoulderY))
        torsoPath.addLine(to: CGPoint(x: cx, y: hipY))
        ctx.stroke(torsoPath, with: .color(self.color), style: style)

        // MARK: Head

        let headRect = CGRect(
            x: cx - headR,
            y: headCY - headR,
            width: headR * 2,
            height: headR * 2
        )
        ctx.fill(Circle().path(in: headRect), with: .color(self.color))

        // MARK: Front limbs (near side, full color)

        if rightForward {
            self.drawLeg(
                in: &ctx, hip: hip, thigh: thigh, calf: calf,
                thighAngle: rThighAng, kneeBend: rKnee,
                style: style, color: self.color
            )
            self.drawArm(
                in: &ctx, shoulder: shoulder,
                upper: upperArm, fore: forearm,
                armAngle: rArmAng, elbowBend: rElbow,
                style: style, color: self.color
            )
        } else {
            self.drawLeg(
                in: &ctx, hip: hip, thigh: thigh, calf: calf,
                thighAngle: lThighAng, kneeBend: lKnee,
                style: style, color: self.color
            )
            self.drawArm(
                in: &ctx, shoulder: shoulder,
                upper: upperArm, fore: forearm,
                armAngle: lArmAng, elbowBend: lElbow,
                style: style, color: self.color
            )
        }
    }

    // MARK: - Limb Drawing

    private func drawLeg(
        in ctx: inout GraphicsContext,
        hip: CGPoint,
        thigh: CGFloat,
        calf: CGFloat,
        thighAngle: Double,
        kneeBend: Double,
        style: StrokeStyle,
        color: Color
    ) {
        let thighRad = thighAngle * .pi / 180
        let calfRad = (thighAngle - kneeBend) * .pi / 180

        let knee = CGPoint(
            x: hip.x + thigh * sin(thighRad),
            y: hip.y + thigh * cos(thighRad)
        )
        let foot = CGPoint(
            x: knee.x + calf * sin(calfRad),
            y: knee.y + calf * cos(calfRad)
        )

        var path = Path()
        path.move(to: hip)
        path.addLine(to: knee)
        path.addLine(to: foot)
        ctx.stroke(path, with: .color(color), style: style)
    }

    private func drawArm(
        in ctx: inout GraphicsContext,
        shoulder: CGPoint,
        upper: CGFloat,
        fore: CGFloat,
        armAngle: Double,
        elbowBend: Double,
        style: StrokeStyle,
        color: Color
    ) {
        let armRad = armAngle * .pi / 180
        let foreRad = (armAngle + elbowBend) * .pi / 180

        let elbow = CGPoint(
            x: shoulder.x + upper * sin(armRad),
            y: shoulder.y + upper * cos(armRad)
        )
        let hand = CGPoint(
            x: elbow.x + fore * sin(foreRad),
            y: elbow.y + fore * cos(foreRad)
        )

        var armPath = Path()
        armPath.move(to: shoulder)
        armPath.addLine(to: elbow)
        armPath.addLine(to: hand)

        ctx.stroke(armPath, with: .color(color), style: style)
    }
}
