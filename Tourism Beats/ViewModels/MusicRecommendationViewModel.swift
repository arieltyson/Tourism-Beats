//
//  MusicRecommendationViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import MusicKit

class MusicRecommendationViewModel: ObservableObject {
    @Published var songTitle: String = "Loading..."
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isAuthorized: Bool = false
    @Published var isMusicFeatureAvailable: Bool = true

    let city: CityModel
    private let musicService: MusicServiceProtocol

    init(city: CityModel, musicService: MusicServiceProtocol = MusicService()) {
        self.city = city
        self.musicService = musicService
    }
    
    // Check and request for authorization only when necessary to allow normal functioning of app (App Store Connect: 5.1.1 Legal: Privacy - Data Collection and Storage)
    func requestMusicAccessIfNeeded() async {
        let status = await MusicAuthorization.request()

        await MainActor.run {
            self.isAuthorized = (status == .authorized)
            self.isMusicFeatureAvailable = self.isAuthorized
        }
        
        if isAuthorized {
            await loadhPopularSong()
        }
    }

    private func loadhPopularSong() async {
        do {
            let song = try await musicService.fetchPopularSong(for: city.name)
            
            await MainActor.run {
                self.songTitle = song.title
                self.artistName = song.artistName
                self.songImage = song.artwork?.url(width: 300, height: 300)
            }
        } catch {
            await MainActor.run {
                self.songTitle = "No song found"
                self.artistName = ""
            }
            print("Error fetching song data: \(error)")
        }
    }
}
