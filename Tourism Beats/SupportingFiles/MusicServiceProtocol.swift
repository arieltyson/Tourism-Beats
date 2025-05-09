import Foundation
import MusicKit

protocol MusicServiceProtocol {
    func fetchPopularSong(for city: String) async throws -> Song
}
