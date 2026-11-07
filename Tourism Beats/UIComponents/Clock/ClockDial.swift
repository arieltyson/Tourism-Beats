import SwiftUI

// MARK: - ClockDial

/// The clock's still face: the dial, its minute ticks, and its numerals.
///
/// Drawn as one canvas rather than seventy-two views. Nothing here moves
/// with the time, so the dial is drawn once and stays put while the hands
/// turn above it.
struct ClockDial: View {
    let style: ClockFaceStyle

    var body: some View {
        Canvas { context, size in
            let layout = ClockDialLayout(size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let face = CGRect(
                x: center.x - layout.radius,
                y: center.y - layout.radius,
                width: layout.radius * 2,
                height: layout.radius * 2
            )

            context.fill(Circle().path(in: face), with: .color(self.style.face))
            context.translateBy(x: center.x, y: center.y)

            ClockDialTicks.draw(in: context, layout: layout, style: self.style)
            ClockDialNumerals.draw(in: context, layout: layout, style: self.style)
        }
    }
}

// MARK: - ClockDialTicks

/// The sixty minute ticks, those on the hours a little bolder.
private enum ClockDialTicks {
    private static let minutesPerDial = 60
    private static let minutesPerHour = 5

    static func draw(in context: GraphicsContext, layout: ClockDialLayout, style: ClockFaceStyle) {
        let length = layout.tickOuterRadius - layout.tickInnerRadius

        for minute in 0 ..< Self.minutesPerDial {
            let isHour = minute.isMultiple(of: Self.minutesPerHour)
            let width = layout.radius * (isHour ? ClockFaceTokens.hourTickWidth : ClockFaceTokens.minuteTickWidth)
            let tick = CGRect(x: -width / 2, y: -layout.tickOuterRadius, width: width, height: length)

            var tickContext = context
            tickContext.rotate(by: .degrees(Double(minute) / Double(Self.minutesPerDial) * 360))
            tickContext.fill(Capsule().path(in: tick), with: .color(isHour ? style.ink : style.ticks))
        }
    }
}

// MARK: - ClockDialNumerals

/// The twelve hour numerals, upright, in the reader's own digits.
private enum ClockDialNumerals {
    static func draw(in context: GraphicsContext, layout: ClockDialLayout, style: ClockFaceStyle) {
        let bounds = CGSize(width: layout.radius, height: layout.radius)

        for hour in 1 ... 12 {
            // The numerals are part of a drawing that scales with the dial,
            // so their size follows the dial rather than Dynamic Type. The
            // card reads the time aloud and in text, and switches to a text
            // card at accessibility sizes.
            let numeral = context.resolve(
                Text(hour, format: .number)
                    .font(.system(size: layout.numeralSize, weight: .medium, design: .rounded))
                    .foregroundStyle(style.ink)
            )
            let size = numeral.measure(in: bounds)
            context.draw(numeral, at: layout.numeralCenter(forHour: hour, size: size))
        }
    }
}
