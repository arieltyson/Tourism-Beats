import Foundation
import MusicKit

actor MusicService: MusicProtocol {
    static let shared = MusicService()

    private var chartCache: [String: (Date, AppSong)] = [:]
    private let cacheDuration: TimeInterval = 3 * 60 * 60 // 3 hours
    private static let decoder = JSONDecoder()

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

    func fetchTopSong(for city: CityModel) async throws -> AppSong {
        let storefront = try Self.validStorefront(from: city.country.code)
        let cityCacheKey = Self.cityCacheKey(for: city, storefront: storefront)

        if let song = self.cachedSong(for: cityCacheKey) {
            return song
        }

        let devToken: String
        do {
            devToken = try await DeveloperTokenGenerator.shared
                .generateDeveloperToken()
        } catch { throw MusicServiceError.tokenGenerationError(error) }

        if let citySong = try await self.fetchCityTopSongIfAvailable(
            for: city,
            storefront: storefront,
            developerToken: devToken
        ) {
            self.chartCache[cityCacheKey] = (Date.now, citySong)
            return citySong
        }

        let countrySong = try await self.fetchCountryTopSong(
            storefront: storefront,
            developerToken: devToken
        )
        self.chartCache[cityCacheKey] = (Date.now, countrySong)
        return countrySong
    }

    func fetchTopSong(countryCode: String) async throws -> AppSong {
        let storefront = try Self.validStorefront(from: countryCode)

        if let song = self.cachedSong(for: Self.countryCacheKey(storefront: storefront)) {
            return song
        }

        let devToken: String
        do {
            devToken = try await DeveloperTokenGenerator.shared
                .generateDeveloperToken()
        } catch { throw MusicServiceError.tokenGenerationError(error) }

        return try await self.fetchCountryTopSong(
            storefront: storefront,
            developerToken: devToken
        )
    }

    private func fetchCountryTopSong(
        storefront: String,
        developerToken: String
    ) async throws -> AppSong {
        let cacheKey = Self.countryCacheKey(storefront: storefront)

        if let song = self.cachedSong(for: cacheKey) {
            return song
        }

        let url = try self.makeURL(
            path: "/v1/catalog/\(storefront)/charts",
            queryItems: [
                URLQueryItem(name: "types", value: "songs"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )

        guard let data = try await self.performRequest(
            url: url,
            developerToken: developerToken,
            storefrontFailure: .storefrontNotAvailable
        )
        else {
            throw MusicServiceError.storefrontNotAvailable
        }

        do {
            let decoded = try Self.decoder.decode(
                AppleMusicChartResponse.self,
                from: data
            )
            guard
                let chart = decoded.results?.songs?.first,
                let apiSong = chart.data.first,
                let song = AppSong(appleNode: apiSong)
            else { throw MusicServiceError.noSongFoundInChart }

            self.chartCache[cacheKey] = (Date.now, song)
            return song
        } catch let decodeErr {
            throw MusicServiceError.decodingError(decodeErr)
        }
    }

    private func fetchCityTopSongIfAvailable(
        for city: CityModel,
        storefront: String,
        developerToken: String
    ) async throws -> AppSong? {
        let playlists = try await self.fetchCityChartPlaylists(
            storefront: storefront,
            developerToken: developerToken
        )

        guard
            let matchedPlaylist = Self.bestMatchingCityPlaylist(
                for: city,
                in: playlists
            )
        else {
            return nil
        }

        return try await self.fetchFirstTrack(
            fromPlaylistID: matchedPlaylist.id,
            storefront: storefront,
            developerToken: developerToken
        )
    }

    private func fetchCityChartPlaylists(
        storefront: String,
        developerToken: String
    ) async throws -> [AppleMusicAPIPlaylist] {
        let url = try self.makeURL(
            path: "/v1/catalog/\(storefront)/charts",
            queryItems: [
                URLQueryItem(name: "types", value: "playlists"),
                URLQueryItem(name: "with", value: "cityCharts"),
                URLQueryItem(name: "limit", value: "100")
            ]
        )

        guard let data = try await self.performRequest(
            url: url,
            developerToken: developerToken,
            storefrontFailure: nil
        )
        else {
            return []
        }

        do {
            let decoded = try Self.decoder.decode(
                AppleMusicChartResponse.self,
                from: data
            )
            return decoded.results?.playlists?.flatMap(\.data) ?? []
        } catch let decodeErr {
            throw MusicServiceError.decodingError(decodeErr)
        }
    }

    private func fetchFirstTrack(
        fromPlaylistID playlistID: String,
        storefront: String,
        developerToken: String
    ) async throws -> AppSong? {
        let url = try self.makeURL(
            path: "/v1/catalog/\(storefront)/playlists/\(playlistID)",
            queryItems: [
                URLQueryItem(name: "include", value: "tracks")
            ]
        )

        guard let data = try await self.performRequest(
            url: url,
            developerToken: developerToken,
            storefrontFailure: nil
        )
        else {
            return nil
        }

        do {
            let decoded = try Self.decoder.decode(
                AppleMusicPlaylistResponse.self,
                from: data
            )
            return Self.firstPlayableSong(from: decoded)
        } catch let decodeErr {
            throw MusicServiceError.decodingError(decodeErr)
        }
    }

    private func performRequest(
        url: URL,
        developerToken: String,
        storefrontFailure: MusicServiceError?
    ) async throws -> Data? {
        var request = URLRequest(url: url)
        request.addValue(
            "Bearer \(developerToken)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicServiceError.networkError(URLError(.badServerResponse))
        }

        if let storefrontFailure,
           httpResponse.statusCode == 400 || httpResponse.statusCode == 404
        {
            throw storefrontFailure
        }

        if httpResponse.statusCode == 400 || httpResponse.statusCode == 404 {
            return nil
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw MusicServiceError.apiError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    private func makeURL(
        path: String,
        queryItems: [URLQueryItem]
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw MusicServiceError.invalidURL
        }
        return url
    }

    private func cachedSong(for key: String) -> AppSong? {
        guard let (timestamp, song) = self.chartCache[key] else { return nil }
        guard Date.now.timeIntervalSince(timestamp) < self.cacheDuration else {
            return nil
        }
        return song
    }

    private static func validStorefront(from countryCode: String) throws -> String {
        let code = countryCode.uppercased()
        guard code.count == 2 else {
            throw MusicServiceError.invalidCountryCode(countryCode)
        }
        return code.lowercased()
    }

    private static func countryCacheKey(storefront: String) -> String {
        "country|\(storefront)"
    }

    private static func cityCacheKey(for city: CityModel, storefront: String) -> String {
        "city|\(storefront)|\(self.normalizedSearchText(city.name))"
    }

    private static func bestMatchingCityPlaylist(
        for city: CityModel,
        in playlists: [AppleMusicAPIPlaylist]
    ) -> AppleMusicAPIPlaylist? {
        let searchTerms = Self.citySearchTerms(for: city)

        return playlists
            .compactMap { playlist -> (playlist: AppleMusicAPIPlaylist, score: Int)? in
                guard let name = playlist.attributes?.name else { return nil }
                let score = Self.matchScore(
                    playlistName: name,
                    cityTerms: searchTerms
                )
                guard score > 0 else { return nil }
                return (playlist, score)
            }
            .max { lhs, rhs in lhs.score < rhs.score }?
            .playlist
    }

    private static func citySearchTerms(for city: CityModel) -> [String] {
        var terms: [String] = [city.name]

        if let simplifiedName = city.name.split(separator: ",").first {
            terms.append(String(simplifiedName))
        }

        let saintVariants = terms.flatMap { term in
            [
                term,
                term.replacingOccurrences(of: "St.", with: "Saint"),
                term.replacingOccurrences(of: "Saint", with: "St.")
            ]
        }

        var seen = Set<String>()
        return saintVariants.compactMap { term in
            let normalized = Self.normalizedSearchText(term)
            guard normalized.count >= 3 else { return nil }
            guard seen.insert(normalized).inserted else { return nil }
            return normalized
        }
    }

    private static func normalizedSearchText(_ text: String) -> String {
        text
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map { $0.lowercased() }
            .joined(separator: " ")
    }

    private static func matchScore(
        playlistName: String,
        cityTerms: [String]
    ) -> Int {
        let normalizedName = Self.normalizedSearchText(playlistName)
        let paddedName = " \(normalizedName) "

        return cityTerms.reduce(0) { currentBest, term in
            let exactScore = normalizedName == term ? 120 : 0
            let wordBoundaryScore = paddedName.contains(" \(term) ") ? 100 : 0
            let substringScore = normalizedName.contains(term) ? 70 : 0
            return max(currentBest, exactScore, wordBoundaryScore, substringScore)
        }
    }

    private static func firstPlayableSong(
        from response: AppleMusicPlaylistResponse
    ) -> AppSong? {
        if let included = response.included {
            let includedByID = Dictionary(
                uniqueKeysWithValues: included.map { ($0.id, $0) }
            )

            if let trackReferences = response.data.first?.relationships?.tracks?.data {
                for trackReference in trackReferences {
                    if let includedSong = includedByID[trackReference.id],
                       let song = AppSong(appleNode: includedSong)
                    {
                        return song
                    }
                }
            }

            if let includedSong = included.first,
               let song = AppSong(appleNode: includedSong)
            {
                return song
            }
        }

        if let relationshipSong = response.data.first?.relationships?.tracks?.data?.first {
            return AppSong(appleNode: relationshipSong)
        }

        return nil
    }
}
