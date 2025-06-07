import Foundation
import MusicKit

// MARK: - App-Specific Song Model
struct AppSong {
    let id: MusicItemID
    let title: String
    let artistName: String
    let artworkURL: URL?
}

// MARK: - Decodable Structs for Apple Music API Response
struct AppleMusicChartResponse: Decodable {
    let results: ChartResults?
}

struct ChartResults: Decodable {
    let songs: [ChartData]?
}

struct ChartData: Decodable {
    let data: [AppleMusicAPISong]
}

struct AppleMusicAPISong: Decodable {
    let id: String
    let attributes: SongAttributes?
}

struct SongAttributes: Decodable {
    let name: String
    let artistName: String
    let artwork: ArtworkAPI?
}

struct ArtworkAPI: Decodable {
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
