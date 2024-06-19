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

    var body: some View {
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
            }
            .padding()
        }
        //.navigationBarBackButtonHidden(true)
        .onAppear {
            print("TouristAttractionView appeared for \(cityName)")
        }
    }
}

struct TouristAttractionView_Previews: PreviewProvider {
    static var previews: some View {
        TouristAttractionView(cityName: "London", videoName: "big_ben_video")
    }
}
