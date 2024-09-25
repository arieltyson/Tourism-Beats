//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI
import TipKit
import UIKit

struct TouristAttractionView: View {
    var city: CityModel
    @State private var navigateBack = false
    @State private var showMusicRecommendations = false
    @State private var showCitySelectionView = false
    
    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                GradientProvider.gradients.randomElement()?.edgesIgnoringSafeArea(.all)
            } else {
                UIKitGradientBackgroundWrapper()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                HStack{
                    VStack(alignment: .leading) {
                        Text("\(city.name), \(city.country.name)  \(city.country.flag)" )
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .italic()
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    Image(city.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .padding(.all)
                    
                }
                .padding(1)
                .background(Rectangle().foregroundColor(.white))
                .cornerRadius(15)
                .shadow(radius: 15)
                
                Spacer()
                
                HStack {
                    TimeWidgetView(cityName: city.name)
                        .frame(maxWidth: .infinity)
                    
                    WeatherWidgetView(cityName: city.name)
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "chevron.left.2")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    Text("Swipe left")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .navigationDestination(isPresented: $showMusicRecommendations) {
                MusicRecommendationView(viewModel: MusicRecommendationViewModel(city: city),fallbackView: FallbackMusicCardView())
            }
            .navigationDestination(isPresented: $showCitySelectionView) {
                CitySelectionView()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -50 { // Left swipe
                        showMusicRecommendations = true
                    } else if value.translation.width > 50 { // Right swipe
                        showCitySelectionView = true
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    navigateBack = true
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                        Text("🌎")
                            .foregroundColor(.white)
                    }
                }
            }
            
            if #available(iOS 18.0, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white)
                        .popoverTip(HighlightTip(), arrowEdge: .top)
                }
            }
        }
        .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
        .onAppear {
            print("TouristAttractionView appeared for \(city.name)")
        }
        .navigationDestination(isPresented: $navigateBack) {
            CitySelectionView()
        }
    }
}
