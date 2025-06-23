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

    private var hasLoadedData = false
    private var playableSong: Song?
    var songID: MusicItemID?

    init(
        city: CityModel,
        musicService: MusicProtocol = MusicService.shared
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
            songID = appSong.id
            songTitle = appSong.title
            artistName = appSong.artistName
            songImage = appSong.artworkURL
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
        guard songID != nil else { return }

        playbackErrorMessage = nil

        if ApplicationMusicPlayer.shared.state.playbackStatus == .playing {
            ApplicationMusicPlayer.shared.pause()
            isPlaying = false
            return
        }

        if let song = playableSong {
            await play(song)
            return
        }

        do {
            let req = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: songID!
            )
            let resp = try await req.response()

            if let song = resp.items.first {
                playableSong = song
                await play(song)
            }
        } catch {
            handlePlaybackError(error)
        }
    }

    private func play(_ song: Song) async {
        ApplicationMusicPlayer.shared.queue = [song]
        do {
            try await ApplicationMusicPlayer.shared.play()
            isPlaying = true
        } catch {
            handlePlaybackError(error)
        }
    }

    private func handlePlaybackError(_ error: Error) {
        print("🎵 playback error:", error)
        isPlaying = false

        if let me = error as? MusicDataRequest.Error, me.status == 404 {
            playbackErrorMessage = "Song not available in your region"
        } else {
            playbackErrorMessage = "Unable to play song"
        }
    }
}
