import SwiftUI

// MARK: - ClockView

struct ClockView: View {
    let date: Date
    let timeZone: TimeZone

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: radius, y: radius)
            let calendar = Calendar.current.settingTimeZone(self.timeZone)

            ZStack {
                // Background
                Circle()
                    .fill(Color(.systemBackground).opacity(0.8))
                    .shadow(color: .gray.opacity(0.4), radius: 5, x: 2, y: 2)

                // Tick marks
                ForEach(0 ..< 60) { tick in
                    let isHour = tick % 5 == 0
                    Rectangle()
                        .fill(Color.primary)
                        .frame(
                            width: isHour ? 2.5 : 1,
                            height: isHour ? 12 : 6
                        )
                        .offset(y: -radius + (isHour ? 12 : 6) / 2 + 5)
                        .rotationEffect(.degrees(Double(tick) / 60 * 360))
                }

                // Numbers
                ForEach(1 ... 12, id: \.self) { hour in
                    let angle = Angle.degrees(Double(hour) / 12 * 360 - 90)
                    let numberRadius = radius * 0.78
                    let x =
                        center.x + numberRadius * CGFloat(cos(angle.radians))
                    let y =
                        center.y + numberRadius * CGFloat(sin(angle.radians))

                    Text("\(hour)")
                        .font(
                            .system(
                                size: radius * 0.18,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.primary)
                        .position(x: x, y: y)
                }

                // Hands
                HandShape(length: radius * 0.55)
                    .fill(Color.primary)
                    .rotationEffect(self.hourAngle(using: calendar))
                    .shadow(radius: 1)

                HandShape(length: radius * 0.75)
                    .fill(Color.primary)
                    .rotationEffect(self.minuteAngle(using: calendar))
                    .shadow(radius: 1)

                HandShape(length: radius * 0.9, isSecondHand: true)
                    .fill(Color.red)
                    .rotationEffect(self.secondAngle(using: calendar))
                    .shadow(color: .red, radius: 2)

                // Center dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
            .animation(
                .interpolatingSpring(stiffness: 300, damping: 15),
                value: calendar.component(.second, from: self.date)
            )
        }
    }

    // MARK: Angle Computations

    private func hourAngle(using cal: Calendar) -> Angle {
        let comps = cal.dateComponents([.hour, .minute], from: self.date)
        let h = Double(comps.hour ?? 0).truncatingRemainder(dividingBy: 12)
        let m = Double(comps.minute ?? 0)
        return .degrees((h + m / 60) / 12 * 360)
    }

    private func minuteAngle(using cal: Calendar) -> Angle {
        let comps = cal.dateComponents([.minute, .second], from: self.date)
        let m = Double(comps.minute ?? 0)
        let s = Double(comps.second ?? 0)
        return .degrees((m + s / 60) / 60 * 360)
    }

    private func secondAngle(using cal: Calendar) -> Angle {
        let s = Double(cal.component(.second, from: self.date))
        return .degrees(s / 60 * 360)
    }

    // MARK: Hand Shape

    private struct HandShape: Shape {
        let length: CGFloat
        var isSecondHand: Bool = false

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width: CGFloat = self.isSecondHand ? 1.5 : 4.0
            // Rounded rectangle extending upward from center
            path.addRoundedRect(
                in: CGRect(
                    x: rect.midX - width / 2,
                    y: rect.midY - self.length,
                    width: width,
                    height: self.length
                ),
                cornerSize: CGSize(width: width / 2, height: width / 2)
            )
            // Small circle at the base for visual aesthetic
            path.addEllipse(
                in: CGRect(
                    x: rect.midX - width * 1.5,
                    y: rect.midY - width * 1.5,
                    width: width * 3,
                    height: width * 3
                )
            )
            return path
        }
    }
}

private extension Calendar {
    func settingTimeZone(_ tz: TimeZone) -> Calendar {
        var cal = self
        cal.timeZone = tz
        return cal
    }
}
