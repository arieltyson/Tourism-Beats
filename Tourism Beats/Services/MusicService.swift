import Foundation
import MusicKit

actor MusicService: MusicProtocol {
    static let shared = MusicService()
    private static let cacheVersion = "v2"

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
        var nextURL: URL? = try self.makeURL(
            path: "/v1/catalog/\(storefront)/playlists",
            queryItems: [
                URLQueryItem(
                    name: "filter[storefront-chart]",
                    value: storefront
                )
            ]
        )

        var playlists: [AppleMusicAPIPlaylist] = []
        var pageCount = 0

        while let url = nextURL, pageCount < 8 {
            pageCount += 1

            guard let data = try await self.performRequest(
                url: url,
                developerToken: developerToken,
                storefrontFailure: nil
            )
            else {
                break
            }

            do {
                let decoded = try Self.decoder.decode(
                    AppleMusicPlaylistsResponse.self,
                    from: data
                )
                playlists.append(contentsOf: decoded.data)
                nextURL = Self.nextURL(from: decoded.next)
            } catch let decodeErr {
                throw MusicServiceError.decodingError(decodeErr)
            }
        }

        return playlists
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
        "country|\(self.cacheVersion)|\(storefront)"
    }

    private static func cityCacheKey(for city: CityModel, storefront: String) -> String {
        "city|\(self.cacheVersion)|\(storefront)|\(self.normalizedSearchText(city.name))"
    }

    private static func bestMatchingCityPlaylist(
        for city: CityModel,
        in playlists: [AppleMusicAPIPlaylist]
    ) -> AppleMusicAPIPlaylist? {
        let searchTerms = Self.citySearchTerms(for: city)
        let preferredTitles = Set(
            Self.preferredCityChartTitles(for: city).map(Self.normalizedSearchText)
        )

        return playlists
            .compactMap { playlist -> (playlist: AppleMusicAPIPlaylist, score: Int)? in
                guard let name = playlist.attributes?.name else { return nil }
                let normalizedName = Self.normalizedSearchText(name)
                let exactTitleBonus = preferredTitles.contains(normalizedName) ? 400 : 0
                let curatorBonus =
                    playlist.attributes?.curatorName?.localizedStandardContains("Apple Music") == true
                    ? 25 : 0
                let score = Self.matchScore(
                    playlistName: name,
                    cityTerms: searchTerms
                ) + exactTitleBonus + curatorBonus
                guard score > 0 else { return nil }
                return (playlist, score)
            }
            .max { lhs, rhs in lhs.score < rhs.score }?
            .playlist
    }

    private static func citySearchTerms(for city: CityModel) -> [String] {
        var terms = Self.cityDisplayNames(for: city)

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

    private static func preferredCityChartTitles(for city: CityModel) -> [String] {
        let displayNames = Self.cityDisplayNames(for: city)
        var titles: [String] = []

        for name in displayNames {
            titles.append("Top 25: \(name)")
            titles.append("Top 25 \(name)")
        }

        return Self.uniquedStrings(titles)
    }

    private static func cityDisplayNames(for city: CityModel) -> [String] {
        let aliasKey =
            "\(city.country.code.uppercased())|\(Self.normalizedSearchText(city.name))"
        let aliases = Self.cityChartAliases[aliasKey] ?? []
        return Self.uniquedStrings(aliases + [city.name])
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
            let exactScore = normalizedName == term ? 180 : 0
            let top25ExactScore =
                normalizedName == "top 25 \(term)" ||
                normalizedName == "top 25 \(term) apple music" ||
                normalizedName == "top 25 \(term) city"
                ? 240 : 0
            let top25BoundaryScore =
                paddedName.contains(" top 25 \(term) ") ? 220 : 0
            let wordBoundaryScore = paddedName.contains(" \(term) ") ? 100 : 0
            let substringScore = normalizedName.contains(term) ? 70 : 0
            return max(
                currentBest,
                exactScore,
                top25ExactScore,
                top25BoundaryScore,
                wordBoundaryScore,
                substringScore
            )
        }
    }

    private static func nextURL(from next: String?) -> URL? {
        guard let next else { return nil }

        if let absoluteURL = URL(string: next), absoluteURL.scheme != nil {
            return absoluteURL
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = next
        return components.url
    }

    private static func uniquedStrings(_ strings: [String]) -> [String] {
        var seen = Set<String>()

        return strings.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            guard seen.insert(trimmed.lowercased()).inserted else { return nil }
            return trimmed
        }
    }

    private static let cityChartAliases: [String: [String]] = [
        "US|new york": ["New York City"]
    ]

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
