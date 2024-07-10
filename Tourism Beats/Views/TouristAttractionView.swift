//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI

struct TouristAttractionView: View {
    var cityName: String
    var countryName: String
    var videoName: String
    
    @State private var navigateBack = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VideoPlayerView(videoName: videoName)
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
                            Text("Back")
                        }
                    }
                }
            }
            
            .onAppear {
                print("TouristAttractionView appeared for \(cityName)")
            }
            .navigationDestination(isPresented: $navigateBack) {
                CitySelectionView()
            }
        }
    }
}

struct TouristAttractionView_Previews: PreviewProvider {
    static var previews: some View {
        TouristAttractionView(cityName: "London", countryName: "England", videoName: "big_ben_video")
    }
}
