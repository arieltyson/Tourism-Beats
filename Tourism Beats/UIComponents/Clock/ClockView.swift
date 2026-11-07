import SwiftUI

// MARK: - ClockView

/// An analog clock showing the time in a city.
///
/// The face is light by day and dark by night in the city. Updated once a
/// second, the hands sweep smoothly between updates, or tick from second to
/// second when Reduce Motion is on.
struct ClockView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    let date: Date
    let timeZone: TimeZone

    /// The moment the hands show, which leads `date` by a tick while they
    /// sweep toward it.
    @State private var handsDate: Date?

    var body: some View {
        let style = ClockFaceStyle(
            phase: ClockFacePhase(date: self.date, timeZone: self.timeZone),
            contrast: self.contrast
        )
        let angles = ClockHandAngles(date: self.handsDate ?? self.date, timeZone: self.timeZone)

        ZStack {
            ClockDial(style: style)

            ClockHand.hour
                .fill(style.ink)
                .rotationEffect(angles.hour)

            ClockHand.minute
                .fill(style.ink)
                .rotationEffect(angles.minute)

            ClockPin(diameter: ClockFaceTokens.hubDiameter)
                .fill(style.ink)

            ClockHand.second
                .fill(style.accent)
                .rotationEffect(angles.second)

            ClockPin(diameter: ClockFaceTokens.capDiameter)
                .fill(style.accent)

            ClockPin(diameter: ClockFaceTokens.pinDiameter)
                .fill(style.face)
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: self.date, initial: true) { oldDate, newDate in
            let sweeps = !self.reduceMotion
            withAnimation(ClockSweep.animation(from: oldDate, to: newDate, sweeps: sweeps)) {
                self.handsDate = ClockSweep.target(for: newDate, sweeps: sweeps)
            }
        }
        // The card around the clock reads the time aloud.
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    HStack {
        ClockView(date: .now, timeZone: .current)
        ClockView(date: .now, timeZone: TimeZone(secondsFromGMT: 12 * 3_600) ?? .current)
    }
    .padding()
    .background(.indigo)
}
