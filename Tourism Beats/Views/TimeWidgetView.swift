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
                .frame(width: 100, height: 100)
                .padding(.bottom, 10)
            
            Text(viewModel.currentTime)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .cornerRadius(15)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 175, height: 250)
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.5)).shadow(radius: 5))
        .padding()
    }
}
