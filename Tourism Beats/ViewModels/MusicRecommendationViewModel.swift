//
//  MusicRecommendationViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import MusicKit
import SwiftUI

class MusicRecommendationViewModel: ObservableObject {
    @Published var songTitle: String = "Loading..."
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isAuthorized: Bool = false

    let city: CityModel
    private let musicService: MusicServiceProtocol

    init(city: CityModel, musicService: MusicServiceProtocol = MusicService()) {
        self.city = city
        self.musicService = musicService
        checkMusicAuthorization()
    }

    func checkMusicAuthorization() {
        Task {
            let status = await MusicAuthorization.request()
            self.isAuthorized = (status == .authorized)

            if isAuthorized {
                await fetchPopularSong()
            } else {
                print("Music access not authorized.")
            }
        }
    }

    @MainActor
    private func fetchPopularSong() async {
        do {
            let song = try await musicService.fetchPopularSong(for: city.name)
            self.songTitle = song.title
            self.artistName = song.artistName
            self.songImage = song.artwork?.url(width: 300, height: 300)
        } catch {
            self.songTitle = "No song found"
            self.artistName = ""
            print("Error fetching song data: \(error)")
        }
    }
}
