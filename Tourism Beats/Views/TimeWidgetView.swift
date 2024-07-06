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
        Text("Current Time: \(viewModel.currentTime)")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}
