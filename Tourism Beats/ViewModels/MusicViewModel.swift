import AVFoundation
@preconcurrency import Combine
import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicViewModel: ObservableObject {
    // Display
    @Published var songTitle: String = "Loading…"
    @Published var artistName: String = ""
    @Published var songImage: URL?

    // Apple playback state
    @Published var isPlaying = false
    @Published var playbackErrorMessage: String?
    @Published var userFeedbackMessage: String?

    // UI state for pills
    @Published var isSpotifySearching = false

    let city: CityModel
    private let musicService: MusicProtocol

    private var hasLoadedData = false

    // Apple playback
    private var playableSong: Song?
    private var appleSong: AppSong?  // ← hold Apple song 

    // Spotify
    private var spotifyMirroredSong: AppSong?  // ← hold Spotify mirror

    // Playback state monitoring
    private var cancellables = Set<AnyCancellable>()
    private var playbackStateTask: Task<Void, Never>?
    private var lastKnownPlaybackState: MusicKit.MusicPlayer.PlaybackStatus =
        .stopped

    init(city: CityModel, musicService: MusicProtocol = MusicService.shared) {
        self.city = city
        self.musicService = musicService
        setupPlaybackStateMonitoring()
    }

    deinit {
        playbackStateTask?.cancel()
    }

    // MARK: - Playback State Monitoring

    private func setupPlaybackStateMonitoring() {
        // App lifecycle
        NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.handleAppBecameActive()
            }
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: UIApplication.willResignActiveNotification
        )
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.handleAppWillResignActive()
            }
        }
        .store(in: &cancellables)

        // Audio interruptions
        NotificationCenter.default.publisher(
            for: AVAudioSession.interruptionNotification
        )
        .sink { [weak self] notification in
            Task { @MainActor in
                await self?.handleAudioInterruption(notification)
            }
        }
        .store(in: &cancellables)

        // Periodic sync
        startPlaybackStateMonitoring()
    }

    private func startPlaybackStateMonitoring() {
        playbackStateTask?.cancel()
        playbackStateTask = Task {
            while !Task.isCancelled {
                await syncPlaybackState()
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1s
            }
        }
    }

    private func handleAppBecameActive() async {
        await syncPlaybackState()
        if appleSong != nil {
            startPlaybackStateMonitoring()
        }
    }

    private func handleAppWillResignActive() async {
        playbackStateTask?.cancel()
        if appleSong != nil {
            lastKnownPlaybackState =
                ApplicationMusicPlayer.shared.state.playbackStatus
        }
    }

    private func handleAudioInterruption(_ notification: Notification) async {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey]
                as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            if isPlaying {
                isPlaying = false
                lastKnownPlaybackState = .interrupted
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey]
                as? UInt {
                let options = AVAudioSession.InterruptionOptions(
                    rawValue: optionsValue
                )
                if options.contains(.shouldResume) {
                    await syncPlaybackState()
                }
            }
        @unknown default:
            break
        }
    }

    private func syncPlaybackState() async {
        guard appleSong != nil else { return }
        let player = ApplicationMusicPlayer.shared
        let status = player.state.playbackStatus
        if isPlaying != (status == .playing) {
            isPlaying = (status == .playing)
        }
        lastKnownPlaybackState = status
    }

    // MARK: - Lifecycle
    /// Load metadata without prompting for Apple authorization.
    func requestAccessAndLoadTopSong() async {
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
        userFeedbackMessage = nil
        spotifyMirroredSong = nil  // reset any prior mirror

        do {
            let appSong = try await musicService.fetchTopSong(
                countryCode: city.country.code
            )
            appleSong = appSong  // ← keep Apple song
            songTitle = appSong.title
            artistName = appSong.artistName
            songImage = appSong.artworkURL
        } catch let error as MusicService.MusicServiceError {
            if case .storefrontNotAvailable = error {
                songTitle = "Music Not Available"
                artistName =
                    "Apple Music charts are not available in \(city.country.name)."
            } else {
                songTitle = "Could Not Load Song"
                artistName = "An unexpected error occurred."
            }
            print("🎵 fetch error:", error)
        } catch {
            songTitle = "Could Not Load Song"
            artistName = error.localizedDescription
            print("🎵 fetch error:", error)
        }
    }

    // MARK: - Apple Music
    func handleAppleMusicAction() async {
        userFeedbackMessage = nil
        playbackErrorMessage = nil

        // Request permission only when user taps
        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }

        // Subscription check (best-effort)
        do {
            let sub = try await MusicSubscription.current
            guard sub.canPlayCatalogContent else { return }
        } catch {
            // try anyway; errors will be surfaced via playback failure
        }

        await togglePlayback()
    }

    private func togglePlayback() async {
        guard let appSong = appleSong else { return }  // ← use Apple song only

        let player = ApplicationMusicPlayer.shared
        let currentStatus = player.state.playbackStatus

        // Pause if already playing
        if currentStatus == .playing {
            player.pause()
            isPlaying = false
            lastKnownPlaybackState = .paused
            return
        }

        // Resume/Play
        if let song = playableSong {
            await play(song)
            return
        }

        // Convert AppSong ID → MusicItemID and fetch song
        guard let musicKitID = appSong.musicKitID else { return }

        do {
            let req = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: musicKitID
            )
            let resp = try await req.response()
            if let song = resp.items.first {
                playableSong = song
                await play(song)
            }
        } catch {}
    }

    private func play(_ song: Song) async {
        ApplicationMusicPlayer.shared.queue = [song]
        do {
            try await ApplicationMusicPlayer.shared.play()
            isPlaying = true
            lastKnownPlaybackState = .playing
        } catch {
            isPlaying = false
            lastKnownPlaybackState = .stopped
        }
    }

    // MARK: - Spotify
    func handleSpotifyAction() async {
        userFeedbackMessage = nil
        playbackErrorMessage = nil

        // Require app installed
        guard let spotifyURL = URL(string: "spotify://"),
            UIApplication.shared.canOpenURL(spotifyURL)
        else {
            return
        }

        // Use the Apple chart result as the source of truth for title/artist
        guard let apple = appleSong else { return }

        // If we already mirrored once, reuse instantly
        if let s = spotifyMirroredSong, let deep = s.deepLinkURL {
            await open(deep)
            return
        }

        // If Apple Music is playing, Spotify will interrupt; our interruption
        // handler will update UI state appropriately.
        isSpotifySearching = true
        defer { isSpotifySearching = false }

        do {
            let mirrored = try await SpotifyService().mirror(
                title: apple.title,
                artist: apple.artistName,
                countryCode: city.country.code
            )
            spotifyMirroredSong = mirrored
            if let deep = mirrored.deepLinkURL {
                await open(deep)
            }
        } catch {}
    }

    private func open(_ url: URL) async {
        if #available(iOS 17.0, *) {
            _ = await UIApplication.shared.open(url)
        } else {
            UIApplication.shared.open(url, options: [:]) { _ in }
        }
    }
}
