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
        let viewModel = MusicViewModel(city: Self.city, musicService: service)

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.availability != .failed)
        #expect(viewModel.artistName != "cancelled")

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.songTitle == "Song Title")
        #expect(viewModel.availability == .available)
    }

    @Test func realFailureShowsAPlainMessageAndCanBeRetried() async {
        let service = StubMusicService(results: [.failure(URLError(.notConnectedToInternet))])
        let viewModel = MusicViewModel(city: Self.city, musicService: service)

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
        let viewModel = MusicViewModel(city: Self.city, musicService: service)

        await viewModel.requestAccessAndLoadTopSong()

        #expect(viewModel.availability == .unavailable)
        #expect(!viewModel.availability.showsPlayers)
        #expect(viewModel.songTitle == "Music Not Available")
        #expect(!viewModel.artistName.localizedStandardContains("Apple"))
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
            source: .appleMusic,
            id: "song",
            title: "Song Title",
            artistName: "Artist",
            artworkURL: nil,
            deepLinkURL: nil
        )
    }
}
