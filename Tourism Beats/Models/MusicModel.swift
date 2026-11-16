import Foundation

// MARK: - AppSong

/// A chart song, as the music page shows and plays it.
/// - Note: `id` is the song's Apple Music ID in the chart's storefront.
public struct AppSong: Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let artistName: String
    public let artworkURL: URL?
    /// International Standard Recording Code - storefront-agnostic identifier
    public let isrc: String?

    public init(
        id: String,
        title: String,
        artistName: String,
        artworkURL: URL?,
        isrc: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.isrc = isrc
    }
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
            id: appleNode.id,
            title: attrs.name,
            artistName: attrs.artistName,
            artworkURL: attrs.artwork?.artworkURL(),
            isrc: attrs.isrc
        )
    }
}
