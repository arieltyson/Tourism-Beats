// MARK: - MusicPlaybackPhase

/// Where the page's song is in playing.
enum MusicPlaybackPhase: Equatable, Sendable {
    case stopped
    /// Play was pressed and the song is on its way. The controls already
    /// show it as playing, so the tap is answered the moment it lands.
    case starting
    case playing

    /// Whether the controls show the song as playing.
    var showsPlaying: Bool { self != .stopped }

    /// How VoiceOver describes the song's state.
    var accessibilityValue: String {
        switch self {
        case .stopped: "Paused"
        case .starting: "Loading"
        case .playing: "Playing"
        }
    }
}
