import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicRecommendationViewModel: ObservableObject {
    @Published var songTitle: String = "Loading..."
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isMusicFeatureAvailable = true
    @Published var isPlaying = false

    let city: CityModel
    private let musicService: MusicServiceProtocol
    private let player = ApplicationMusicPlayer.shared

    private var songID: MusicItemID?

    init(
        city: CityModel,
        musicService: MusicServiceProtocol = MusicService()
    ) {
        self.city = city
        self.musicService = musicService
    }

    func requestAccessAndLoadTopSong() async {
        let status = await MusicAuthorization.request()
        self.isMusicFeatureAvailable = (status == .authorized)

        guard isMusicFeatureAvailable else {
            songTitle = "Music Access Required"
            artistName = "Please grant permission in Settings."
            return
        }
        await fetchTopSong()
    }

    /// Fetch song metadata via Apple Music REST API service.
    private func fetchTopSong() async {
        songTitle = "Loading Top Song…"
        artistName = "for \(city.country.name)"
        songImage = nil
        isPlaying = false

        do {
            let appSong = try await musicService.fetchTopSong(
                countryCode: city.country.code
            )
            self.songID = appSong.id
            self.songTitle = appSong.title
            self.artistName = appSong.artistName
            self.songImage = appSong.artworkURL
        } catch {
            self.songTitle = "Could Not Load Song"
            self.artistName = error.localizedDescription
            print("🎵 fetch error:", error)
        }
    }

    func togglePlayback() async {
        guard let id = songID else { return }

        // If we think we're playing, pause.
        if isPlaying {
            player.pause()
            self.isPlaying = false
        } else {
            // If paused, fetch the full Song object using MusicKit and then play.
            do {
                // 1. Fetch the native MusicKit.Song object using its ID.
                let request = MusicCatalogResourceRequest<Song>(
                    matching: \.id,
                    equalTo: id
                )
                let response = try await request.response()

                // 2. Queue and play the fetched song.
                if let song = response.items.first {
                    player.queue = [song]
                    try await player.play()
                    self.isPlaying = true
                }
            } catch {
                print("🎵 playback error:", error)
                // If playback fails, ensure our state reflects that.
                self.isPlaying = false
            }
        }
    }
}
