import AVFoundation
@preconcurrency import Combine
import Foundation
@preconcurrency import MusicKit
import SwiftUI
import UIKit

@MainActor
final class MusicViewModel: ObservableObject {
    // MARK: Display

    @Published var songTitle: String = "Loading…"
    @Published var artistName: String = ""
    @Published var songImage: URL?

    // MARK: Playback state

    @Published var isPlaying = false
    @Published var userFeedbackMessage: String?
    @Published var isSpotifySearching = false

    // MARK: Dependencies

    let city: CityModel
    private let musicService: MusicProtocol

    // MARK: Internal state

    private var hasLoadedData = false
    private var playableSong: Song? // Apple Music playable item
    private var appleSong: AppSong? // Apple Music chart result
    private var spotifyMirroredSong: AppSong? // Mirror of Apple result

    // MARK: Observers

    private var cancellables = Set<AnyCancellable>()
    private var playbackStateTask: Task<Void, Never>?

    // MARK: Init

    init(city: CityModel, musicService: MusicProtocol = MusicService.shared) {
        self.city = city
        self.musicService = musicService
        self.setupPlaybackStateMonitoring()
    }

    deinit {
        playbackStateTask?.cancel()
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
            for: UIApplication.willResignActiveNotification
        )
        .sink { [weak self] _ in
            Task { @MainActor in await self?.handleAppWillResignActive() }
        }
        .store(in: &self.cancellables)

        NotificationCenter.default.publisher(
            for: AVAudioSession.interruptionNotification
        )
        .sink { [weak self] note in
            Task { @MainActor in await self?.handleAudioInterruption(note) }
        }
        .store(in: &self.cancellables)

        self.startPlaybackStateMonitoring()
    }

    private func startPlaybackStateMonitoring() {
        self.playbackStateTask?.cancel()
        self.playbackStateTask = Task {
            while !Task.isCancelled {
                await self.syncPlaybackState()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func handleAppBecameActive() async {
        await self.syncPlaybackState()
        if self.appleSong != nil { self.startPlaybackStateMonitoring() }
    }

    private func handleAppWillResignActive() async {
        self.playbackStateTask?.cancel()
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

    private func fetchTopSongMetadata() async {
        self.songTitle = "Loading Top Song…"
        self.artistName = "for \(self.city.country.name)"
        self.songImage = nil
        self.isPlaying = false
        self.playableSong = nil
        self.userFeedbackMessage = nil
        self.spotifyMirroredSong = nil

        do {
            let result = try await musicService.fetchTopSong(
                countryCode: self.city.country.code
            )
            self.appleSong = result
            self.songTitle = result.title
            self.artistName = result.artistName
            self.songImage = result.artworkURL
        } catch let error as MusicService.MusicServiceError {
            switch error {
            case .storefrontNotAvailable:
                songTitle = "Music Not Available"
                artistName =
                    "Apple Music charts are not available in \(city.country.name)."
            default:
                songTitle = "Could Not Load Song"
                artistName = "An unexpected error occurred."
            }
        } catch {
            self.songTitle = "Could Not Load Song"
            self.artistName = error.localizedDescription
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

    // MARK: - Skip Controls

    /// Skips backward: restarts the current song.
    func skipBackward() {
        guard self.playableSong != nil else { return }
        ApplicationMusicPlayer.shared.restartCurrentEntry()
    }

    /// Skips forward to the next entry in the queue.
    /// No-op when the queue has only one song.
    func skipForward() async {
        guard self.playableSong != nil else { return }
        let player = ApplicationMusicPlayer.shared
        do {
            try await player.skipToNextEntry()
        } catch {
            // Gracefully ignore — no next entry in a single-song queue.
        }
    }

    // MARK: - Spotify

    func handleSpotifyAction() async {
        self.userFeedbackMessage = nil

        guard let apple = appleSong else {
            self.userFeedbackMessage = "No song available to play."
            return
        }

        let isSpotifyInstalled = self.canOpenSpotifyApp()

        // Reuse a previous successful mirror if we have one
        if let mirrored = spotifyMirroredSong, let deep = mirrored.deepLinkURL {
            await self.openSpotifyURL(deep, isAppInstalled: isSpotifyInstalled)
            return
        }

        // Pause Apple Music before handing off to Spotify
        if ApplicationMusicPlayer.shared.state.playbackStatus == .playing {
            ApplicationMusicPlayer.shared.pause()
            self.isPlaying = false
        }

        self.isSpotifySearching = true
        defer { isSpotifySearching = false }

        do {
            let mirrored = try await SpotifyService().mirror(
                title: apple.title,
                artist: apple.artistName,
                countryCode: self.city.country.code
            )
            self.spotifyMirroredSong = mirrored

            if let deep = mirrored.deepLinkURL {
                await self.openSpotifyURL(deep, isAppInstalled: isSpotifyInstalled)
            } else {
                await self.openSpotifySearchFallback(
                    title: apple.title,
                    artist: apple.artistName,
                    isAppInstalled: isSpotifyInstalled
                )
            }
        } catch {
            await self.handleSpotifyError(
                error,
                title: apple.title,
                artist: apple.artistName,
                isAppInstalled: isSpotifyInstalled
            )
        }
    }

    // MARK: - Spotify Deep Linking

    private func canOpenSpotifyApp() -> Bool {
        guard let scheme = URL(string: "spotify://") else { return false }
        return UIApplication.shared.canOpenURL(scheme)
    }

    private func openSpotifyURL(_ url: URL, isAppInstalled: Bool) async {
        if isAppInstalled, let appURL = spotifyAppURLIfPossible(forWebURL: url) {
            if await self.openURL(appURL) { return }
        }

        // Fall back to web (which may still universal-link into Spotify)
        _ = await self.openURL(url)
        if !(UIApplication.shared.canOpenURL(url)) {
            await MainActor.run {
                self.userFeedbackMessage =
                    "Unable to open Spotify. Please check if the app is installed."
            }
        }
    }

    private func spotifyAppURLIfPossible(forWebURL webURL: URL) -> URL? {
        guard webURL.host == "open.spotify.com" else { return nil }
        let components = webURL.pathComponents
        guard components.count >= 3, components[1] == "track" else {
            return nil
        }
        let trackID = components[2]
        return URL(string: "spotify://track/\(trackID)")
    }

    private func openSpotifySearchFallback(
        title: String,
        artist: String,
        isAppInstalled: Bool
    ) async {
        let query = "\(title) \(artist)"
        let encoded = self.encodeForURLPath(query)

        if isAppInstalled,
           let appURL = URL(string: "spotify://search/\(encoded)"),
           await openURL(appURL)
        {
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "open.spotify.com"
        components.path = "/search/\(encoded)"

        if let webURL = components.url {
            if await self.openURL(webURL) { return }
        }

        await MainActor.run {
            self.userFeedbackMessage =
                "Unable to open Spotify search. Please try again."
        }
    }

    private func handleSpotifyError(
        _ error: Error,
        title: String,
        artist: String,
        isAppInstalled: Bool
    ) async {
        if let spotifyError = error as? SpotifyService.ServiceError {
            switch spotifyError {
            case let .api(statusCode):
                if statusCode == 401 {
                    await MainActor.run {
                        self.userFeedbackMessage =
                            "Spotify authentication expired. Please try again."
                    }
                    return
                } else if statusCode == 404 {
                    // Not found → search
                    await self.openSpotifySearchFallback(
                        title: title,
                        artist: artist,
                        isAppInstalled: isAppInstalled
                    )
                    return
                } else {
                    await MainActor.run {
                        self.userFeedbackMessage =
                            "Spotify service unavailable. Trying search instead…"
                    }
                    await self.openSpotifySearchFallback(
                        title: title,
                        artist: artist,
                        isAppInstalled: isAppInstalled
                    )
                    return
                }
            case .notFound:
                await self.openSpotifySearchFallback(
                    title: title,
                    artist: artist,
                    isAppInstalled: isAppInstalled
                )
                return
            }
        }

        // Unknown error → search fallback
        await MainActor.run {
            self.userFeedbackMessage =
                "Unable to connect to Spotify. Trying search instead…"
        }
        await self.openSpotifySearchFallback(
            title: title,
            artist: artist,
            isAppInstalled: isAppInstalled
        )
    }

    // MARK: - URL Opening

    private func openURL(_ url: URL) async -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }

        if #available(iOS 17.0, *) {
            return await UIApplication.shared.open(url)
        } else {
            return await withCheckedContinuation { continuation in
                UIApplication.shared.open(url, options: [:]) { result in
                    continuation.resume(returning: result)
                }
            }
        }
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

    // MARK: - Encoding

    private func encodeForURLPath(_ value: String) -> String {
        value.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlPathAllowed.union(
                .urlQueryAllowed
            )
        ) ?? value
    }
}
