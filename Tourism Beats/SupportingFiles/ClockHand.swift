//
//  ClockHand.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 13/7/24.
//

import SwiftUI

struct ClockHand: Shape {
    var length: CGFloat
    var thickness: CGFloat
    var angle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + length * cos(CGFloat(angle.radians) - .pi / 2),
                                 y: rect.midY + length * sin(CGFloat(angle.radians) - .pi / 2)))
        return path.strokedPath(StrokeStyle(lineWidth: thickness, lineCap: .round))
    }
}

struct ClockFaceView: View {
    @State private var currentTime = CurrentTime()
    private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(radius: 10)
            
            // Hour Hand
            ClockHand(length: 50, thickness: 6, angle: currentTime.hourAngle)
                .stroke(Color.black)
                .rotationEffect(currentTime.hourAngle)
            
            // Minute Hand
            ClockHand(length: 70, thickness: 4, angle: currentTime.minuteAngle)
                .stroke(Color.black)
                .rotationEffect(currentTime.minuteAngle)
            
            // Second Hand
            ClockHand(length: 90, thickness: 2, angle: currentTime.secondAngle)
                .stroke(Color.red)
                .rotationEffect(currentTime.secondAngle)
        }
        .frame(width: 200, height: 200)
        .onReceive(timer) { _ in
            self.currentTime = CurrentTime()
        }
    }
}

struct CurrentTime {
    var hour: Int
    var minute: Int
    var second: Int
    
    init() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: Date())
        hour = components.hour ?? 0
        minute = components.minute ?? 0
        second = components.second ?? 0
    }
    
    var hourAngle: Angle {
        return .degrees(Double(hour % 12) / 12 * 360 + Double(minute) / 60 * 30)
    }
    
    var minuteAngle: Angle {
        return .degrees(Double(minute) / 60 * 360)
    }
    
    var secondAngle: Angle {
        return .degrees(Double(second) / 60 * 360)
    }
}
