import Combine
import Foundation
import Observation

@MainActor
@Observable
final class MusicViewModel {
    // MARK: Display

    private(set) var availability: MusicAvailability = .loading
    private(set) var songTitle: String = "Loading…"
    private(set) var artistName: String = ""
    private(set) var songImage: URL?

    // MARK: Playback state

    private(set) var playback: MusicPlaybackPhase = .stopped

    /// Whether the song can go back to its beginning: it's the player's song.
    private(set) var canRestart = false

    /// A short note the listener can act on, shown under the players.
    private(set) var userFeedbackMessage: String?

    /// Whether Apple Music's subscription offer is showing.
    var isShowingSubscriptionOffer = false

    /// Whether the controls show the song as playing.
    var isPlaying: Bool { self.playback.showsPlaying }

    // MARK: Dependencies

    @ObservationIgnored let city: CityModel
    @ObservationIgnored private let musicService: MusicProtocol
    @ObservationIgnored private let player: MusicPlaybackControlling

    // MARK: Internal state

    @ObservationIgnored private var hasLoadedData = false
    @ObservationIgnored private var appleSong: AppSong?
    @ObservationIgnored private var startTask: Task<Void, Never>?
    @ObservationIgnored private var playerObservation: AnyCancellable?

    // MARK: Init

    init(
        city: CityModel,
        musicService: MusicProtocol = MusicService.shared,
        player: MusicPlaybackControlling? = nil
    ) {
        self.city = city
        self.musicService = musicService
        self.player = player ?? AppleMusicPlayback.shared
        self.playerObservation = self.player.observeChanges { [weak self] in
            self?.syncPlaybackState()
        }
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
        self.appleSong = nil
        self.userFeedbackMessage = nil
        self.syncPlaybackState()

        do {
            let result = try await musicService.fetchTopSong(for: self.city)
            self.appleSong = result
            self.songTitle = result.title
            self.artistName = result.artistName
            self.songImage = result.artworkURL
            self.availability = .available
            // Find it in the listener's catalog now, so play starts at once.
            self.player.prefetch(result)
            self.syncPlaybackState()
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

    /// Plays or pauses the song.
    ///
    /// The controls change the moment this is called; the music follows. A
    /// second tap while the song is still on its way takes the first back,
    /// so every tap does what the button showed.
    func togglePlayback() {
        guard let song = self.appleSong else { return }
        self.userFeedbackMessage = nil

        if self.playback.showsPlaying {
            self.stop(song)
        } else {
            self.playback = .starting
            self.startTask = Task { await self.start(song) }
        }
    }

    private func start(_ song: AppSong) async {
        do {
            try await self.player.play(song)
            if Task.isCancelled {
                // Taken back while starting; the music mustn't begin anyway.
                if self.player.isCurrent(song) { self.player.pause() }
                return
            }
            self.playback = .playing
            self.canRestart = true
        } catch {
            guard !Task.isCancelled else { return }
            self.playback = .stopped
            self.present(error)
        }
    }

    private func stop(_ song: AppSong) {
        self.startTask?.cancel()
        self.startTask = nil
        if self.player.isCurrent(song) { self.player.pause() }
        self.playback = .stopped
    }

    private func present(_ error: MusicPlaybackError) {
        switch error {
        case .needsSubscription:
            self.isShowingSubscriptionOffer = true
        case .accessDenied:
            self.userFeedbackMessage = "Allow Apple Music in Settings to play songs here."
        case .notInCatalog:
            self.userFeedbackMessage = "This song isn’t on Apple Music in your country or region."
        case .failed:
            self.userFeedbackMessage = "Couldn’t play this song. Try again."
        case .cancelled:
            break
        }
    }

    /// Takes the song back to its beginning.
    func restart() {
        guard let song = self.appleSong, self.player.isCurrent(song) else { return }
        self.player.restart()
    }

    /// Follows the player, which another page, Control Center or a call may
    /// have changed. A song on its way stays shown as playing until it starts.
    private func syncPlaybackState() {
        guard let song = self.appleSong else {
            self.playback = .stopped
            self.canRestart = false
            return
        }

        self.canRestart = self.player.isCurrent(song)
        let isPlaying = self.player.isPlaying(song)

        switch self.playback {
        case .starting:
            if isPlaying { self.playback = .playing }
        case .stopped, .playing:
            self.playback = isPlaying ? .playing : .stopped
        }
    }

    // MARK: - Spotify

    /// Hands the song to Spotify, pausing Apple Music so the two don't play
    /// over each other. Returns the links the view opens.
    func spotifyHandoff() -> SpotifyHandoff? {
        guard let song = self.appleSong else { return nil }
        if self.playback.showsPlaying { self.stop(song) }
        return SpotifyHandoff(title: song.title, artist: song.artistName)
    }
}
