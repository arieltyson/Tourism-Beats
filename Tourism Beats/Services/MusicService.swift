//
//  MusicService.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import MusicKit

class MusicService: MusicServiceProtocol {
    func fetchPopularSong(for city: String) async throws -> Song {
        let request = MusicCatalogSearchRequest(term: city, types: [Song.self])
        let response = try await request.response()

        if let song = response.songs.first {
            return song
        } else {
            throw MusicServiceError.noSongFound
        }
    }

    enum MusicServiceError: Error {
        case noSongFound
    }
}
