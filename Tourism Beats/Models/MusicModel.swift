import Foundation
import MusicKit

// MARK: - App-Specific Song Model

struct AppSong: Sendable {
    let id: MusicItemID
    let title: String
    let artistName: String
    let artworkURL: URL?
}

// MARK: - Decodable & Sendable Structs for Apple Music API Response

struct AppleMusicChartResponse: Decodable, Sendable {
    let results: ChartResults?
}

struct ChartResults: Decodable, Sendable {
    let songs: [ChartData]?
}

struct ChartData: Decodable, Sendable {
    let data: [AppleMusicAPISong]
}

struct AppleMusicAPISong: Decodable, Sendable {
    let id: String
    let attributes: SongAttributes?
}

struct SongAttributes: Decodable, Sendable {
    let name: String
    let artistName: String
    let artwork: ArtworkAPI?
}

struct ArtworkAPI: Decodable, Sendable {
    let url: String

    func artworkURL(width: Int = 600, height: Int = 600) -> URL? {
        let sizedURLString = url.replacingOccurrences(
            of: "{w}",
            with: "\(width)"
        )
        .replacingOccurrences(of: "{h}", with: "\(height)")
        return URL(string: sizedURLString)
    }
}
