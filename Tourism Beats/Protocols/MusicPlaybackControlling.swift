import Combine

// MARK: - MusicPlaybackControlling

/// Plays a chart song, so the music page can be tested without the system
/// music player.
@MainActor
protocol MusicPlaybackControlling: AnyObject {
    /// Looks the song up ahead of a tap, when that needs no permission prompt,
    /// so pressing play only has to start the music.
    func prefetch(_ song: AppSong)

    /// Starts the song, resuming it if it's already the player's song.
    func play(_ song: AppSong) async throws(MusicPlaybackError)

    /// Pauses the player.
    func pause()

    /// Takes the player's song back to its beginning.
    func restart()

    /// Whether the song is the player's current song.
    func isCurrent(_ song: AppSong) -> Bool

    /// Whether the song is the player's current song and is playing.
    func isPlaying(_ song: AppSong) -> Bool

    /// Calls `handler` after anything that may change what's playing, until
    /// the returned value is released.
    func observeChanges(_ handler: @escaping @MainActor () -> Void) -> AnyCancellable
}
