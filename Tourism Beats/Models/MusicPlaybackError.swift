// MARK: - MusicPlaybackError

/// Why a song couldn't start, in the terms the listener can act on.
enum MusicPlaybackError: Error, Equatable, Sendable {
    /// The listener hasn't allowed access to Apple Music.
    case accessDenied
    /// The song isn't in the listener's Apple Music catalog.
    case notInCatalog
    /// The listener can subscribe to Apple Music to play it.
    case needsSubscription
    /// The tap was taken back before the song started.
    case cancelled
    /// Anything else, such as a lost connection.
    case failed
}
