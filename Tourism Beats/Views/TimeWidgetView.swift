//
//  TimeWidgetView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 6/7/24.
//

import SwiftUI

struct TimeWidgetView: View {
    @ObservedObject var viewModel: TimeViewModel
    
    init(cityName: String) {
        self.viewModel = TimeViewModel(cityName: cityName)
    }
    
    var body: some View {
        VStack {
            ClockFaceView (
                hour: viewModel.currentHour,
                minute: viewModel.currentMinute,
                second: viewModel.currentSecond
            )
                .frame(width: 175, height: 175)
                .padding(.bottom, 20)
            
            Text(viewModel.currentTime)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.black).shadow(radius: 5))
        .padding()
    }
}
