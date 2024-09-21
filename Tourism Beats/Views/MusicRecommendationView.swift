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
    var city: City
    @State private var songTitle: String = "Loading..."
    @State private var artistName: String = "Loading..."
    @State private var songImage: URL?
    @State private var isAuthorized: Bool = false
    
    var body: some View {
        VStack {
            if let songImage = songImage {
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
            
            Text(songTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text(artistName)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 5)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.indigo.opacity(0.7), Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            checkMusicAuthorization()
        }
    }
    
    private func checkMusicAuthorization() {
        Task {
            let status = await MusicAuthorization.request()
            isAuthorized = (status == .authorized)
            
            if isAuthorized {
                fetchPopularSong(for: city.name)
            } else {
                print("Music access not authorized.")
            }
        }
    }
    
    private func fetchPopularSong(for city: String) {
        Task {
            do {
                let request = MusicCatalogSearchRequest(term: city, types: [Song.self])
                let response = try await request.response()
                
                if let song = response.songs.first {
                    songTitle = song.title
                    artistName = song.artistName
                    songImage = song.artwork?.url(width: 300, height: 300)
                } else {
                    songTitle = "No song found"
                    artistName = ""
                }
            } catch {
                print("Error fetching song data: \(error)")
            }
        }
    }
}
