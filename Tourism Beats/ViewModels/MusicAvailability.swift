/// Whether a city's top song can be shown and played.
enum MusicAvailability: Equatable, Sendable {
    case loading
    case available
    /// The city's country has no top-songs chart.
    case unavailable
    /// The chart couldn't be reached; trying again may work.
    case failed

    /// The players show the song only once it has arrived. While it's on
    /// its way, the song header alone says so; the players hold their place
    /// with placeholders, so nothing moves when the song lands.
    var showsSongDetails: Bool { self == .available }

    /// Players appear only while there's a song, or one is on its way;
    /// with nothing to play, the song header alone explains why.
    var showsPlayers: Bool {
        switch self {
        case .loading, .available: true
        case .unavailable, .failed: false
        }
    }
}
