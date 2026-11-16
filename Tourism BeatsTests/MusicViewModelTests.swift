import Combine
import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - MusicViewModelTests

@MainActor
struct MusicViewModelTests {
    private static let city = CityModel(
        id: "san-francisco-us",
        name: "San Francisco",
        country: CountryModel(name: "United States of America", code: "US", flag: "🇺🇸"),
        imageURL: URL.documentsDirectory,
        coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.42),
        timeZoneIdentifier: "America/Los_Angeles"
    )

    @Test(arguments: [
        URLError(.cancelled) as Error,
        CancellationError() as Error,
        MusicService.MusicServiceError.networkError(URLError(.cancelled)) as Error
    ])
    func interruptedLoadIsNotShownAsAFailureAndRetries(error: Error) async {
        let service = StubMusicService(results: [.failure(error)])
        let viewModel = MusicViewModel(city: Self.city, musicService: service, player: StubPlayer())

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.availability != .failed)
        #expect(viewModel.artistName != "cancelled")

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.songTitle == "Song Title")
        #expect(viewModel.availability == .available)
    }

    @Test func realFailureShowsAPlainMessageAndCanBeRetried() async {
        let service = StubMusicService(results: [.failure(URLError(.notConnectedToInternet))])
        let viewModel = MusicViewModel(city: Self.city, musicService: service, player: StubPlayer())

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.availability == .failed)
        #expect(!viewModel.availability.showsPlayers)
        #expect(viewModel.songTitle == "Couldn’t Load Top Song")
        #expect(viewModel.artistName == "Check your connection and try again.")

        await viewModel.retry()
        #expect(viewModel.availability == .available)
        #expect(viewModel.songTitle == "Song Title")
    }

    /// The message is said once, in the header, without naming the
    /// service behind the chart; the players step aside.
    @Test func unavailableChartsSayItOnceWithoutNamingAService() async {
        let service = StubMusicService(results: [.failure(MusicService.MusicServiceError.storefrontNotAvailable)])
        let viewModel = MusicViewModel(city: Self.city, musicService: service, player: StubPlayer())

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.availability == .unavailable)
        #expect(!viewModel.availability.showsPlayers)
        #expect(viewModel.songTitle == "Music Not Available")
        #expect(!viewModel.artistName.localizedStandardContains("Apple"))
    }

    // MARK: Playback

    @Test func playAnswersTheTapBeforeTheMusicStarts() async {
        let player = StubPlayer()
        let viewModel = await Self.loadedViewModel(player: player)

        viewModel.togglePlayback()

        #expect(viewModel.playback == .starting)
        #expect(viewModel.isPlaying)

        await player.finishPlaying()
        #expect(viewModel.playback == .playing)
        #expect(viewModel.canRestart)
    }

    @Test func aSecondTapWhileStartingTakesTheFirstBack() async {
        let player = StubPlayer()
        let viewModel = await Self.loadedViewModel(player: player)

        viewModel.togglePlayback()
        viewModel.togglePlayback()
        #expect(viewModel.playback == .stopped)

        await player.finishPlaying()
        #expect(viewModel.playback == .stopped)
        #expect(player.pauseCount == 1)
        #expect(player.playCount == 1)
    }

    @Test func loadingTheSongLooksItUpBeforeAnyTap() async {
        let player = StubPlayer()
        _ = await Self.loadedViewModel(player: player)

        #expect(player.prefetched == ["song"])
    }

    @Test func anotherPagesSongTakingOverShowsThisOneStopped() async {
        let player = StubPlayer()
        let viewModel = await Self.loadedViewModel(player: player)
        viewModel.togglePlayback()
        await player.finishPlaying()

        player.currentSongID = "another-song"
        player.notifyChange()

        #expect(viewModel.playback == .stopped)
        #expect(!viewModel.canRestart)
    }

    @Test(arguments: [MusicPlaybackError.accessDenied, .notInCatalog, .failed])
    func aSongThatCantPlaySaysWhatToDo(error: MusicPlaybackError) async {
        let player = StubPlayer(playError: error)
        let viewModel = await Self.loadedViewModel(player: player)

        viewModel.togglePlayback()
        await player.finishPlaying()

        #expect(viewModel.playback == .stopped)
        #expect(viewModel.userFeedbackMessage != nil)
        #expect(!viewModel.isShowingSubscriptionOffer)
    }

    @Test func aListenerWithoutASubscriptionIsOfferedOne() async {
        let player = StubPlayer(playError: .needsSubscription)
        let viewModel = await Self.loadedViewModel(player: player)

        viewModel.togglePlayback()
        await player.finishPlaying()

        #expect(viewModel.isShowingSubscriptionOffer)
        #expect(viewModel.userFeedbackMessage == nil)
    }

    @Test func handingOffToSpotifyPausesAppleMusic() async {
        let player = StubPlayer()
        let viewModel = await Self.loadedViewModel(player: player)
        viewModel.togglePlayback()
        await player.finishPlaying()

        let handoff = viewModel.spotifyHandoff()

        #expect(handoff != nil)
        #expect(viewModel.playback == .stopped)
        #expect(player.pauseCount == 1)
    }

    private static func loadedViewModel(player: StubPlayer) async -> MusicViewModel {
        let viewModel = MusicViewModel(
            city: Self.city,
            musicService: StubMusicService(results: []),
            player: player
        )
        await viewModel.requestAccessAndLoadTopSong()
        return viewModel
    }

    @Test func onlyAnArrivedSongShowsInThePlayers() {
        #expect(MusicAvailability.available.showsSongDetails)
        #expect(!MusicAvailability.loading.showsSongDetails)
        #expect(MusicAvailability.loading.showsPlayers)
    }
}

// MARK: - StubMusicService

/// Returns each queued result in turn, then a song.
private final class StubMusicService: MusicProtocol, @unchecked Sendable {
    private var results: [Result<Void, Error>]

    init(results: [Result<Void, Error>]) {
        self.results = results
    }

    func fetchTopSong(for _: CityModel) async throws -> AppSong {
        if !self.results.isEmpty, case let .failure(error) = self.results.removeFirst() {
            throw error
        }
        return AppSong(
            id: "song",
            title: "Song Title",
            artistName: "Artist",
            artworkURL: nil
        )
    }
}

// MARK: - StubPlayer

/// Holds each play until the test lets it finish, as a slow start would.
@MainActor
private final class StubPlayer: MusicPlaybackControlling {
    private let playError: MusicPlaybackError?
    private var pendingPlay: CheckedContinuation<Void, Never>?
    private var finishedPlays = 0
    private let changes = PassthroughSubject<Void, Never>()

    private(set) var prefetched: [String] = []
    private(set) var playCount = 0
    private(set) var pauseCount = 0
    var currentSongID: String?
    private var isPlayerPlaying = false

    init(playError: MusicPlaybackError? = nil) {
        self.playError = playError
    }

    func prefetch(_ song: AppSong) {
        self.prefetched.append(song.id)
    }

    func play(_ song: AppSong) async throws(MusicPlaybackError) {
        self.playCount += 1
        await withCheckedContinuation { self.pendingPlay = $0 }
        // The caller resumes in this same main-actor job, so once a test sees
        // this count rise, the view model has finished reacting.
        defer { self.finishedPlays += 1 }
        if let playError { throw playError }
        self.currentSongID = song.id
        self.isPlayerPlaying = true
    }

    /// Lets the waiting play finish, and returns once the view model has reacted.
    func finishPlaying() async {
        while self.pendingPlay == nil { await Task.yield() }
        let finished = self.finishedPlays
        self.pendingPlay?.resume()
        self.pendingPlay = nil
        while self.finishedPlays == finished { await Task.yield() }
    }

    func pause() {
        self.pauseCount += 1
        self.isPlayerPlaying = false
    }

    func restart() {}

    func isCurrent(_ song: AppSong) -> Bool {
        self.currentSongID == song.id
    }

    func isPlaying(_ song: AppSong) -> Bool {
        self.isPlayerPlaying && self.isCurrent(song)
    }

    func notifyChange() {
        self.changes.send()
    }

    func observeChanges(_ handler: @escaping @MainActor () -> Void) -> AnyCancellable {
        self.changes.sink { _ in MainActor.assumeIsolated { handler() } }
    }
}
