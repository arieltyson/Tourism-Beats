import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicViewModel: ObservableObject {
    // UI bindings
    @Published var songTitle: String = "Loading…"
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isMusicFeatureAvailable = true
    @Published var isPlaying = false
    @Published var playbackErrorMessage: String?

    let city: CityModel
    private let musicService: MusicProtocol
    private let player = ApplicationMusicPlayer.shared

    private var hasLoadedData = false
    private var playableSong: Song?
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
        playbackErrorMessage = nil

        do {
            let appSong = try await musicService.fetchTopSong(
                countryCode: city.country.code
            )
            self.songID = appSong.id
            self.songTitle = appSong.title
            self.artistName = appSong.artistName
            self.songImage = appSong.artworkURL
        } catch let error as MusicService.MusicServiceError {
            if case .storefrontNotAvailable = error {
                self.songTitle = "Music Not Available"
                self.artistName =
                    "Apple Music charts are not available in \(city.country.name)."
            } else {
                self.songTitle = "Could Not Load Song"
                self.artistName = "An unexpected error occurred."
            }
            print("🎵 fetch error:", error)
        } catch {
            songTitle = "Could Not Load Song"
            artistName = error.localizedDescription
            print("🎵 fetch error:", error)
        }
    }

    func togglePlayback() async {
        guard let id = songID else { return }

        // clear any old playback error
        playbackErrorMessage = nil

        if isPlaying {
            player.pause()
            isPlaying = false
            return
        }

        if let song = playableSong {
            player.queue = [song]
            do {
                try await player.play()
                isPlaying = true
            } catch {
                handlePlaybackError(error)
            }
            return
        }

        // fetch & play
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
            handlePlaybackError(error)
        }
    }

    private func handlePlaybackError(_ error: Error) {
        print("🎵 playback error:", error)
        isPlaying = false

        // If it's a MusicDataRequest.Error with 404, assume region lock
        if let me = error as? MusicDataRequest.Error,
            me.status == 404
        {
            playbackErrorMessage = "Song not available in your region"
        } else {
            playbackErrorMessage = "Unable to play song"
        }
    }
}
