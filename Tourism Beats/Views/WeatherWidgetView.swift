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
            Text(viewModel.weatherCondition)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 10)
            
            Image(systemName: viewModel.weatherIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .padding(.vertical, 10)
            
            Text(viewModel.temperature)
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 10)
        }
        .frame(width: 175, height: 250)
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.5))
            .shadow(radius: 5))
        .padding()
    }
}
