import Foundation

class MusicService: MusicServiceProtocol {

    enum MusicServiceError: Error {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case tokenGenerationError(Error)
        case noSongFoundInChart
        case invalidCountryCode(String)
        case apiError(statusCode: Int)
    }

    func fetchTopSong(countryCode: String) async throws -> AppSong {
        guard !countryCode.isEmpty, countryCode.count == 2 else {
            throw MusicServiceError.invalidCountryCode(countryCode)
        }

        let developerToken: String
        do {
            developerToken =
                try DeveloperTokenGenerator.generateDeveloperToken()
        } catch {
            throw MusicServiceError.tokenGenerationError(error)
        }

        let storefront = countryCode.lowercased()
        guard
            let url = URL(
                string:
                    "https://api.music.apple.com/v1/catalog/\(storefront)/charts?types=songs&limit=1"
            )
        else {
            throw MusicServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(
            "Bearer \(developerToken)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw MusicServiceError.apiError(statusCode: statusCode)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(
                AppleMusicChartResponse.self,
                from: data
            )

            guard let topChart = decodedResponse.results?.songs?.first,
                let topAPISong = topChart.data.first,
                let attributes = topAPISong.attributes
            else {
                throw MusicServiceError.noSongFoundInChart
            }

            return AppSong(
                title: attributes.name,
                artistName: attributes.artistName,
                artworkURL: attributes.artwork?.artworkURL()
            )
        } catch {
            throw MusicServiceError.decodingError(error)
        }
    }
}
