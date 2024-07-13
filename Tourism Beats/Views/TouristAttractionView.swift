//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct TouristAttractionView: View {
    var cityName: String
    var countryName: String
    //var videoName: String
    let meshGradient = GradientProvider.gradients.randomElement() ?? MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .red, .purple, .indigo,
                .orange, .white, .blue,
                .yellow, .green, .mint
            ]
        )
    
    @State private var navigateBack = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                //VideoPlayerView(videoName: videoName)
                Rectangle()
                    .fill(meshGradient)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("\(cityName), \(countryName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .italic()
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    TimeWidgetView(cityName: cityName)
                        .padding(.top, 20)
                    
                    WeatherWidgetView(cityName: cityName)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    NavigationLink(value: "CitySelection") {
                        EmptyView()
                    }.hidden()
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        navigateBack = true
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                            Text("Back")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .onAppear {
                print("TouristAttractionView appeared for \(cityName)")
            }
            .navigationDestination(isPresented: $navigateBack) {
                CitySelectionView()
            }
        }
    }
}

@available(iOS 18.0, *)
struct TouristAttractionView_Previews: PreviewProvider {
    static var previews: some View {
        TouristAttractionView(cityName: "London", countryName: "England"//, videoName: "big_ben_video"
        )
    }
}
