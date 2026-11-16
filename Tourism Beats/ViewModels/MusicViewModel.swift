import AVFoundation
@preconcurrency import Combine
import Foundation
@preconcurrency import MusicKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class MusicViewModel {
    // MARK: Display

    private(set) var availability: MusicAvailability = .loading
    var songTitle: String = "Loading…"
    var artistName: String = ""
    var songImage: URL?

    // MARK: Playback state

    var isPlaying = false
    var userFeedbackMessage: String?

    // MARK: Dependencies

    @ObservationIgnored let city: CityModel
    @ObservationIgnored private let musicService: MusicProtocol

    // MARK: Internal state

    @ObservationIgnored private var hasLoadedData = false
    @ObservationIgnored private var playableSong: Song? // Apple Music playable item
    @ObservationIgnored private var appleSong: AppSong? // Apple Music chart result

    // MARK: Observers

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(city: CityModel, musicService: MusicProtocol = MusicService.shared) {
        self.city = city
        self.musicService = musicService
        self.setupPlaybackStateMonitoring()
    }

    // MARK: - Playback State Monitoring

    private func setupPlaybackStateMonitoring() {
        NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .sink { [weak self] _ in
            Task { @MainActor in await self?.handleAppBecameActive() }
        }
        .store(in: &self.cancellables)

        NotificationCenter.default.publisher(
            for: AVAudioSession.interruptionNotification
        )
        .sink { [weak self] note in
            Task { @MainActor in await self?.handleAudioInterruption(note) }
        }
        .store(in: &self.cancellables)

        // The player announces each change, so the play button follows
        // playback without waking every second to ask.
        ApplicationMusicPlayer.shared.state.objectWillChange
            .sink { [weak self] _ in
                // The change lands after this announcement; read it once it has.
                Task { @MainActor in await self?.syncPlaybackState() }
            }
            .store(in: &self.cancellables)
    }

    private func handleAppBecameActive() async {
        await self.syncPlaybackState()
    }

    private func handleAudioInterruption(_ notification: Notification) async {
        guard
            let userInfo = notification.userInfo,
            let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        switch type {
        case .began:
            if self.isPlaying { self.isPlaying = false }
        case .ended:
            if let rawOpts = userInfo[AVAudioSessionInterruptionOptionKey]
                as? UInt
            {
                let opts = AVAudioSession.InterruptionOptions(rawValue: rawOpts)
                if opts.contains(.shouldResume) { await self.syncPlaybackState() }
            }
        @unknown default:
            break
        }
    }

    private func syncPlaybackState() async {
        guard self.appleSong != nil else { return }
        let status = ApplicationMusicPlayer.shared.state.playbackStatus
        self.isPlaying = (status == .playing)
    }

    // MARK: - Lifecycle

    /// Loads top-song metadata (no Apple Music authorization prompt).
    func requestAccessAndLoadTopSong() async {
        guard !self.hasLoadedData else { return }
        self.hasLoadedData = true
        await self.fetchTopSongMetadata()
    }

    /// Loads the top song again after a failed attempt.
    func retry() async {
        self.hasLoadedData = false
        await self.requestAccessAndLoadTopSong()
    }

    private func fetchTopSongMetadata() async {
        self.availability = .loading
        self.songTitle = "Loading Top Song…"
        self.artistName = "for \(self.city.name)"
        self.songImage = nil
        self.isPlaying = false
        self.playableSong = nil
        self.userFeedbackMessage = nil

        do {
            let result = try await musicService.fetchTopSong(for: self.city)
            self.appleSong = result
            self.songTitle = result.title
            self.artistName = result.artistName
            self.songImage = result.artworkURL
            self.availability = .available
        } catch where Self.isCancellation(error) {
            // The page was scrolled away or closed mid-load. That isn't a
            // failure: load again the next time the page appears.
            self.hasLoadedData = false
        } catch MusicService.MusicServiceError.storefrontNotAvailable {
            // Which service supplies the chart is ours to know, not the listener's.
            self.availability = .unavailable
            self.songTitle = "Music Not Available"
            self.artistName = "Top songs aren’t available in \(self.city.country.name) yet."
        } catch {
            self.availability = .failed
            self.songTitle = "Couldn’t Load Top Song"
            self.artistName = "Check your connection and try again."
        }
    }

    /// Whether an error only means the load was interrupted, including when
    /// the service wraps the underlying network error.
    private static func isCancellation(_ error: Error) -> Bool {
        switch error {
        case is CancellationError:
            true
        case let urlError as URLError:
            urlError.code == .cancelled
        case let MusicService.MusicServiceError.networkError(underlying),
             let MusicService.MusicServiceError.tokenGenerationError(underlying):
            self.isCancellation(underlying)
        default:
            false
        }
    }

    // MARK: - Apple Music

    func handleAppleMusicAction() async {
        self.userFeedbackMessage = nil

        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }

        // Best-effort subscription check; if it throws, we still attempt play.
        if let subscription = try? await MusicSubscription.current,
           subscription.canPlayCatalogContent == false
        {
            return
        }

        await self.togglePlayback()
    }

    private func togglePlayback() async {
        let player = ApplicationMusicPlayer.shared
        if player.state.playbackStatus == .playing {
            player.pause()
            self.isPlaying = false
            return
        }

        if let cached = playableSong {
            await self.play(cached)
            return
        }

        // Resolve into the current storefront
        guard let song = await resolvePlayableSongForCurrentStorefront() else {
            self.userFeedbackMessage =
                "This track isn't available in your Apple Music region."
            return
        }

        self.playableSong = song
        await self.play(song)
    }

    private func play(_ song: Song) async {
        ApplicationMusicPlayer.shared.queue = [song]
        do {
            try await ApplicationMusicPlayer.shared.play()
            self.isPlaying = true
        } catch {
            self.isPlaying = false
        }
    }

    // MARK: - Playback Controls

    /// Restarts the current song from the beginning.
    func skipBackward() {
        guard self.playableSong != nil else { return }
        ApplicationMusicPlayer.shared.restartCurrentEntry()
    }

    // MARK: - Spotify

    /// Hands the song to Spotify, pausing Apple Music so the two don't play
    /// over each other. Returns the links the view opens.
    func spotifyHandoff() -> SpotifyHandoff? {
        guard let apple = self.appleSong else { return nil }

        if ApplicationMusicPlayer.shared.state.playbackStatus == .playing {
            ApplicationMusicPlayer.shared.pause()
            self.isPlaying = false
        }

        return SpotifyHandoff(title: apple.title, artist: apple.artistName)
    }

    // MARK: - Storefront Resolution

    private func resolvePlayableSongForCurrentStorefront() async -> Song? {
        guard let app = appleSong else { return nil }

        // 1) Best: look up by ISRC (storefront-agnostic)
        if let isrc = app.isrc {
            if let byISRC = try? await fetchSongByISRC(isrc) {
                return byISRC
            }
        }

        // 2) Fallback: search in the user's storefront
        return try? await self.searchSongByTitleAndArtist(
            title: app.title,
            artist: app.artistName
        )
    }

    private func fetchSongByISRC(_ isrc: String) async throws -> Song? {
        let request = MusicCatalogResourceRequest<Song>(
            matching: \.isrc,
            equalTo: isrc
        )
        let response = try await request.response()
        return response.items.first
    }

    private func searchSongByTitleAndArtist(title: String, artist: String)
        async throws -> Song?
    {
        var search = MusicCatalogSearchRequest(
            term: "\(title) \(artist)",
            types: [Song.self]
        )
        search.limit = 5
        let response = try await search.response()

        // Prefer exact/near-exact matches
        if let exact = response.songs.first(where: { song in
            song.title.compare(
                title,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
                && song.artistName.compare(
                    artist,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
        }) {
            return exact
        }
        return response.songs.first
    }
}
