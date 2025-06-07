import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicViewModel: ObservableObject {
    @Published var songTitle: String = "Loading…"
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isMusicFeatureAvailable = true
    @Published var isPlaying = false

    let city: CityModel
    private let musicService: MusicProtocol
    private let player = ApplicationMusicPlayer.shared

    private var hasLoadedData = false  // only fetch once
    private var playableSong: Song?  // cache MusicKit song
    private var songID: MusicItemID?

    init(
        city: CityModel,
        musicService: MusicProtocol = MusicService() as MusicProtocol
    ) {
        self.city = city
        self.musicService = musicService
    }

    func requestAccessAndLoadTopSong() async {
        let status = await MusicAuthorization.request()
        isMusicFeatureAvailable = (status == .authorized)

        guard isMusicFeatureAvailable else {
            songTitle = "Music Access Required"
            artistName = "Grant permission in Settings"
            return
        }

        guard !hasLoadedData else { return }
        hasLoadedData = true
        await fetchTopSongMetadata()
    }

    private func fetchTopSongMetadata() async {
        songTitle = "Loading Top Song…"
        artistName = "for \(city.country.name)"
        songImage = nil
        isPlaying = false
        playableSong = nil

        do {
            let appSong = try await musicService.fetchTopSong(
                countryCode: city.country.code
            )
            self.songID = appSong.id
            self.songTitle = appSong.title
            self.artistName = appSong.artistName
            self.songImage = appSong.artworkURL
        } catch {
            songTitle = "Could Not Load Song"
            artistName = error.localizedDescription
            print("🎵 fetch error:", error)
        }
    }

    /// Toggling play/pause reuses a cached MusicKit `Song` if we already fetched it.
    func togglePlayback() async {
        guard let id = songID else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            return
        }

        // If we have a `Song` instance already, just play it
        if let song = playableSong {
            player.queue = [song]
            do {
                try await player.play()
                isPlaying = true
            } catch {
                print("🎵 playback error:", error)
                isPlaying = false
            }
            return
        }

        // Otherwise fetch it once, cache, then play
        do {
            let req = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: id
            )
            let resp = try await req.response()
            if let song = resp.items.first {
                playableSong = song
                player.queue = [song]
                try await player.play()
                isPlaying = true
            }
        } catch {
            print("🎵 playback error:", error)
            isPlaying = false
        }
    }
}
