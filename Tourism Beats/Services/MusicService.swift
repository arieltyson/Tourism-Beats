import Foundation
import MusicKit

class MusicService: MusicProtocol {

    enum MusicServiceError: Error {
        case invalidCountryCode(String)
        case invalidURL
        case apiError(statusCode: Int)
        case noSongFoundInChart
        case decodingError(Error)
        case tokenGenerationError(Error)
    }

    // MARK: - Chart Cache
    // [ countryCode : (timestamp, AppSong) ]
    private static var chartCache: [String: (Date, AppSong)] = [:]
    private let cacheDuration: TimeInterval = 3 * 60 * 60

    func fetchTopSong(countryCode: String) async throws -> AppSong {
        let code = countryCode.uppercased()
        guard code.count == 2 else {
            throw MusicServiceError.invalidCountryCode(countryCode)
        }

        // Return cached if still valid
        if let (ts, song) = Self.chartCache[code],
            Date().timeIntervalSince(ts) < cacheDuration
        {
            return song
        }

        // Generate/​reuse developer token
        let devToken: String
        do {
            devToken = try DeveloperTokenGenerator.generateDeveloperToken()
        } catch {
            throw MusicServiceError.tokenGenerationError(error)
        }

        let storefront = code.lowercased()
        guard
            let url = URL(
                string:
                    "https://api.music.apple.com/v1/catalog/\(storefront)/charts?types=songs&limit=1"
            )
        else {
            throw MusicServiceError.invalidURL
        }

        var req = URLRequest(url: url)
        req.addValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse,
            (200...299).contains(http.statusCode)
        else {
            throw MusicServiceError.apiError(
                statusCode: (resp as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        do {
            let decoded = try JSONDecoder()
                .decode(AppleMusicChartResponse.self, from: data)

            guard
                let chart = decoded.results?.songs?.first,
                let apiSong = chart.data.first,
                let attrs = apiSong.attributes
            else {
                throw MusicServiceError.noSongFoundInChart
            }

            let song = AppSong(
                id: MusicItemID(apiSong.id),
                title: attrs.name,
                artistName: attrs.artistName,
                artworkURL: attrs.artwork?.artworkURL()
            )
            Self.chartCache[code] = (Date(), song)
            return song

        } catch let decodeErr {
            throw MusicServiceError.decodingError(decodeErr)
        }
    }
}
