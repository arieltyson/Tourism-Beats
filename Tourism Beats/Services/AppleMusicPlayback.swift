import AVFoundation
import Combine
@preconcurrency import MusicKit
import UIKit

// MARK: - AppleMusicPlayback

/// Plays chart songs through the app's Apple Music player.
///
/// A chart comes from the city's storefront, so each song is found again in
/// the listener's own catalog before it can play. That lookup is the slow
/// part of a first tap; it runs once per song, ahead of the tap whenever
/// Apple Music access is already allowed, and every page shares its result.
@MainActor
final class AppleMusicPlayback: MusicPlaybackControlling {
    static let shared = AppleMusicPlayback()

    private let player = ApplicationMusicPlayer.shared

    /// Songs found in the listener's catalog, by chart song ID.
    private var catalogSongs: [String: Song] = [:]

    /// Lookups under way, so a prefetch and a tap share one request.
    private var lookups: [String: Task<Song?, any Error>] = [:]

    private init() {}

    // MARK: Playing

    func prefetch(_ song: AppSong) {
        guard MusicAuthorization.currentStatus == .authorized else { return }
        _ = self.lookup(song)
    }

    func play(_ song: AppSong) async throws(MusicPlaybackError) {
        try await self.authorize()

        let catalogSong: Song?
        do {
            catalogSong = try await self.lookup(song).value
        } catch {
            throw .failed
        }
        guard let catalogSong else { throw .notInCatalog }
        guard !Task.isCancelled else { throw .cancelled }

        // Resuming keeps the listener's place and skips buffering again.
        if !self.isCurrent(song) {
            self.player.queue = [catalogSong]
        }

        do {
            try await self.player.play()
        } catch {
            throw await Self.canOfferSubscription() ? .needsSubscription : .failed
        }
    }

    func pause() {
        self.player.pause()
    }

    func restart() {
        self.player.restartCurrentEntry()
    }

    // MARK: State

    func isCurrent(_ song: AppSong) -> Bool {
        guard
            let catalogSong = self.catalogSongs[song.id],
            case let .song(current)? = self.player.queue.currentEntry?.item
        else { return false }
        return current.id == catalogSong.id
    }

    func isPlaying(_ song: AppSong) -> Bool {
        self.player.state.playbackStatus == .playing && self.isCurrent(song)
    }

    func observeChanges(_ handler: @escaping @MainActor () -> Void) -> AnyCancellable {
        let center = NotificationCenter.default
        return Publishers.Merge4(
            // The player announces a change before making it.
            self.player.state.objectWillChange.map { _ in () },
            self.player.queue.objectWillChange.map { _ in () },
            center.publisher(for: AVAudioSession.interruptionNotification).map { _ in () },
            center.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in () }
        )
        .sink { _ in
            // Read the state once the change has landed.
            Task { @MainActor in handler() }
        }
    }

    // MARK: Access

    private func authorize() async throws(MusicPlaybackError) {
        var status = MusicAuthorization.currentStatus
        if status == .notDetermined {
            status = await MusicAuthorization.request()
        }
        guard status == .authorized else { throw .accessDenied }
    }

    /// Whether the song failed only for want of a subscription the listener can start.
    private static func canOfferSubscription() async -> Bool {
        guard let subscription = try? await MusicSubscription.current else { return false }
        return !subscription.canPlayCatalogContent && subscription.canBecomeSubscriber
    }

    // MARK: Catalog lookup

    private func lookup(_ song: AppSong) -> Task<Song?, any Error> {
        if let lookup = self.lookups[song.id] { return lookup }

        let lookup = Task {
            do {
                let catalogSong = try await Self.catalogSong(matching: song)
                self.catalogSongs[song.id] = catalogSong
                return catalogSong
            } catch {
                // A failed lookup is tried again on the next tap.
                self.lookups[song.id] = nil
                throw error
            }
        }
        self.lookups[song.id] = lookup
        return lookup
    }

    /// Finds the chart song in the listener's catalog: by its recording code,
    /// which is the same everywhere, then by title and artist.
    private nonisolated static func catalogSong(matching song: AppSong) async throws -> Song? {
        if let isrc = song.isrc {
            let request = MusicCatalogResourceRequest<Song>(matching: \.isrc, equalTo: isrc)
            if let match = try await request.response().items.first {
                return match
            }
        }

        var search = MusicCatalogSearchRequest(term: "\(song.title) \(song.artistName)", types: [Song.self])
        search.limit = 5
        let songs = try await search.response().songs
        let exact = songs.first { candidate in
            candidate.title.compare(song.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                && candidate.artistName.compare(song.artistName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        return exact ?? songs.first
    }
}
