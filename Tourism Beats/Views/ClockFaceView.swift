//
//  ClockFaceView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 13/7/24.
//

import Foundation
import Combine
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
    var hour: Int
    var minute: Int
    var second: Int
    
    var body: some View {
        let currentTime = CurrentTime(hour: hour, minute: minute, second: second)
        
        return ZStack {
            Circle()
                .fill(Color.white)
                .shadow(radius: 10)
            
            // Hour Hand
            ClockHand(length: 40, thickness: 6, angle: currentTime.hourAngle)
                .stroke(Color.black)
                .rotationEffect(currentTime.hourAngle)
            
            // Minute Hand
            ClockHand(length: 60, thickness: 4, angle: currentTime.minuteAngle)
                .stroke(Color.black)
                .rotationEffect(currentTime.minuteAngle)
            
            // Second Hand
            ClockHand(length: 80, thickness: 2, angle: currentTime.secondAngle)
                .stroke(Color.red)
                .rotationEffect(currentTime.secondAngle)
        }
        .frame(width: 175, height: 175)
        }
    }


struct CurrentTime {
    var hour: Int
    var minute: Int
    var second: Int
    
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
