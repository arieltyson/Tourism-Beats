import Foundation
import MusicKit

class MusicService: MusicServiceProtocol {
    func fetchPopularSong(for city: String) async throws -> Song {
        let request = MusicCatalogSearchRequest(term: city, types: [Song.self])
        let response = try await request.response()

        guard let song = response.songs.first else {
            throw MusicServiceError.noSongFound
        }
            return song
    }

    enum MusicServiceError: Error {
        case noSongFound
    }
}
