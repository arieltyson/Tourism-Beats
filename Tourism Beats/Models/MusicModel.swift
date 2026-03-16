import Foundation
import MusicKit

// MARK: - AppSongSource

/// The catalog a song came from.
public enum AppSongSource: String, Codable, Sendable {
    case appleMusic
    case spotify
}

// MARK: - AppSong

/// Provider-agnostic song model used by the UI and view models.
/// - Note: `id` is the provider’s native identifier (Apple Music or Spotify).
///         Keep it as `String` for portability. Convert to `MusicItemID` only
///         at the point of Apple Music playback.
public struct AppSong: Sendable, Equatable, Hashable {
    public let source: AppSongSource
    public let id: String // Provider ID (AM/Spotify)
    public let title: String
    public let artistName: String
    public let artworkURL: URL?
    /// For Spotify, this will usually be a ready-to-open link like
    /// `https://open.spotify.com/track/{id}`. Apple Music playback is in-app
    /// so this is typically `nil` for AM sources.
    public let deepLinkURL: URL?
    /// International Standard Recording Code - storefront-agnostic identifier
    public let isrc: String?

    public init(
        source: AppSongSource,
        id: String,
        title: String,
        artistName: String,
        artworkURL: URL?,
        deepLinkURL: URL?,
        isrc: String? = nil
    ) {
        self.source = source
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.deepLinkURL = deepLinkURL
        self.isrc = isrc
    }
}

// MARK: - Apple Music conveniences

public extension AppSong {
    /// Convenience for Apple Music playback: converts the provider `id`
    /// to `MusicItemID` **iff** the source is Apple Music.
    var musicKitID: MusicItemID? {
        self.source == .appleMusic ? MusicItemID(self.id) : nil
    }

    /// Useful flags in UI/view models.
    var isAppleMusic: Bool { self.source == .appleMusic }
    var isSpotify: Bool { self.source == .spotify }
}

// MARK: - Apple Music API response models

/// Top-level Apple Music Charts response.
struct AppleMusicChartResponse: Decodable, Sendable {
    let results: ChartResults?
}

struct ChartResults: Decodable, Sendable {
    let songs: [ChartData]?
    let playlists: [PlaylistChartData]?
}

struct ChartData: Decodable, Sendable {
    let data: [AppleMusicAPISong]
}

struct PlaylistChartData: Decodable, Sendable {
    let data: [AppleMusicAPIPlaylist]
}

/// Minimal song node from Apple Music API used for top charts.
struct AppleMusicAPISong: Decodable, Sendable {
    let id: String
    let attributes: SongAttributes?
}

struct AppleMusicAPIPlaylist: Decodable, Sendable {
    let id: String
    let attributes: PlaylistAttributes?
    let relationships: PlaylistRelationships?
}

struct SongAttributes: Decodable, Sendable {
    let name: String
    let artistName: String
    let artwork: ArtworkAPI?
    let isrc: String?
}

struct PlaylistAttributes: Decodable, Sendable {
    let name: String
    let curatorName: String?
}

struct PlaylistRelationships: Decodable, Sendable {
    let tracks: PlaylistTracksRelationship?
}

struct PlaylistTracksRelationship: Decodable, Sendable {
    let data: [AppleMusicAPISong]?
}

struct ArtworkAPI: Decodable, Sendable {
    let url: String

    /// Returns a sized artwork URL by replacing the `{w}` and `{h}` tokens.
    func artworkURL(width: Int = 600, height: Int = 600) -> URL? {
        let sized =
            self.url
            .replacingOccurrences(of: "{w}", with: "\(width)")
            .replacingOccurrences(of: "{h}", with: "\(height)")
        return URL(string: sized)
    }
}

struct AppleMusicPlaylistResponse: Decodable, Sendable {
    let data: [AppleMusicAPIPlaylist]
    let included: [AppleMusicAPISong]?
}

struct AppleMusicPlaylistsResponse: Decodable, Sendable {
    let data: [AppleMusicAPIPlaylist]
    let next: String?
}

// MARK: - Helpers to map AM API → AppSong

extension AppSong {
    /// Create an `AppSong` from an Apple Music API node.
    /// Returns `nil` if required attributes are missing.
    init?(appleNode: AppleMusicAPISong) {
        guard let attrs = appleNode.attributes else { return nil }
        self.init(
            source: .appleMusic,
            id: appleNode.id,
            title: attrs.name,
            artistName: attrs.artistName,
            artworkURL: attrs.artwork?.artworkURL(),
            deepLinkURL: nil,
            isrc: attrs.isrc
        )
    }
}
