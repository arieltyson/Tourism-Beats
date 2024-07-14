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
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(radius: 10)
            
            // Hour Hand
            ClockHand(length: 30, thickness: 5, angle: .degrees(Double(hour % 12) / 12 * 360 + Double(minute) / 60 * 30))
                .stroke(Color.black)
            
            // Minute Hand
            ClockHand(length: 40, thickness: 4, angle: .degrees(Double(minute) / 60 * 360))
                .stroke(Color.black)
            
            // Second Hand
            ClockHand(length: 45, thickness: 2, angle: .degrees(Double(second) / 60 * 360))
                .stroke(Color.red)
        }
        .frame(width: 100, height: 100)
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
