//
//  WeatherWidgetView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 10/7/24.
//

import SwiftUI

struct WeatherWidgetView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    init(cityName: String) {
        self.viewModel = WeatherViewModel(cityName: cityName)
    }
    
    var body: some View {
        VStack {
            Text(viewModel.weatherDescription)
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
}
