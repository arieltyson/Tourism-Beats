//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI

struct TouristAttractionView: View {
    var cityName: String
    var videoName: String
    
    @State private var navigateBack = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VideoPlayerView(videoName: videoName)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text(cityName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .italic()
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
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
        TouristAttractionView(cityName: "London", videoName: "big_ben_video")
    }
}
