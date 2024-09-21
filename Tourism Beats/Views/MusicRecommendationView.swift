//
//  MusicRecommendationView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 19/9/24.
//

import SwiftUI
import MusicKit

@available(iOS 18.0, *)
struct MusicRecommendationView: View {
    @ObservedObject var viewModel: MusicRecommendationViewModel
    
    var body: some View {
        VStack {
            if let songImage = viewModel.songImage {
                AsyncImage(url: songImage) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                        .padding(.top, 50)
                } placeholder: {
                    ProgressView()
                }
            } else {
                ProgressView()
                    .frame(width: 300, height: 300)
            }
            
            Text(viewModel.songTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text(viewModel.artistName)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 5)
            
            Spacer()
            
            SafetyAdvisoryView(viewModel: SafetyAdvisoryViewModel(city: viewModel.city))
            
            Spacer()
        }
        .customNavigationTitle("Apple Music Local 🌆")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.indigo.opacity(0.7), Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
    }
}
