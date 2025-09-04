import Foundation
import MusicKit

actor MusicService: MusicProtocol {
    static let shared = MusicService()

    private var chartCache: [String: (Date, AppSong)] = [:]
    private let cacheDuration: TimeInterval = 3 * 60 * 60  // 3 hours

    private init() {}

    enum MusicServiceError: Error {
        case invalidCountryCode(String)
        case invalidURL
        case apiError(statusCode: Int)
        case noSongFoundInChart
        case decodingError(Error)
        case tokenGenerationError(Error)
        case storefrontNotAvailable
        case networkError(Error)
    }

    func fetchTopSong(countryCode: String) async throws -> AppSong {
        let code = countryCode.uppercased()
        guard code.count == 2 else {
            throw MusicServiceError.invalidCountryCode(countryCode)
        }

        if let (ts, song) = chartCache[code],
            Date().timeIntervalSince(ts) < cacheDuration {
            return song
        }

        let devToken: String
        do {
            devToken = try await DeveloperTokenGenerator.shared
                .generateDeveloperToken()
        } catch { throw MusicServiceError.tokenGenerationError(error) }

        let storefront = code.lowercased()
        guard
            let url = URL(
                string:
                    "https://api.music.apple.com/v1/catalog/\(storefront)/charts?types=songs&limit=1"
            )
        else { throw MusicServiceError.invalidURL }

        var req = URLRequest(url: url)
        req.addValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw MusicServiceError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 400 || http.statusCode == 404 {
            throw MusicServiceError.storefrontNotAvailable
        }
        guard (200...299).contains(http.statusCode) else {
            throw MusicServiceError.apiError(statusCode: http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(
                AppleMusicChartResponse.self,
                from: data
            )
            guard
                let chart = decoded.results?.songs?.first,
                let apiSong = chart.data.first,
                let attrs = apiSong.attributes
            else {
                throw MusicServiceError.noSongFoundInChart
            }

            let song = AppSong(
                source: .appleMusic,
                id: apiSong.id,  // String id (MusicKit-compatible)
                title: attrs.name,
                artistName: attrs.artistName,
                artworkURL: attrs.artwork?.artworkURL(),
                deepLinkURL: nil  // Apple playback is in-app
            )

            chartCache[code] = (Date(), song)
            return song
        } catch let decodeErr {
            throw MusicServiceError.decodingError(decodeErr)
        }
    }
}
