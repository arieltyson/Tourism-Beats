import Foundation

/// Mirrors the Apple Music #1 (by country) on Spotify by searching the same song/artist.
/// Keeps UX parity: same title/artist shown, but playback via Spotify deep link.
actor SpotifyService: MusicProtocol {

    enum ServiceError: Swift.Error {
        case api(Int)
        case notFound
    }

    private let base = URL(string: "https://api.spotify.com/v1")!

    // Original protocol entry point (used if you want Spotify to fetch everything):
    func fetchTopSong(countryCode: String) async throws -> AppSong {
        // 1) Get Apple’s #1
        let appleTop = try await MusicService.shared.fetchTopSong(
            countryCode: countryCode
        )
        // 2) Mirror on Spotify
        return try await mirror(
            title: appleTop.title,
            artist: appleTop.artistName,
            countryCode: countryCode
        )
    }

    // New helper: given Apple’s title/artist, produce a Spotify deep link AppSong.
    func mirror(title: String, artist: String, countryCode: String) async throws
        -> AppSong {
        let token = try await SpotifyAuthManager.shared.validAccessToken()
        let market = countryCode.uppercased()

        guard
            let best = try await searchSpotifyTrack(
                title: title,
                artist: artist,
                market: market,
                token: token
            )
        else {
            throw ServiceError.notFound
        }

        let artwork: URL? = best.album.images.first.flatMap {
            URL(string: $0.url)
        }
        let deep: URL? =
            best.external_urls?["spotify"]
            .flatMap { URL(string: $0) }
            ?? URL(string: "https://open.spotify.com/track/\(best.id)")

        return AppSong(
            source: .spotify,
            id: best.id,
            title: best.name,
            artistName: best.artists.map(\.name).joined(separator: ", "),
            artworkURL: artwork,
            deepLinkURL: deep
        )
    }

    // MARK: - Spotify search

    private func searchSpotifyTrack(
        title: String,
        artist: String,
        market: String,
        token: String
    ) async throws -> Track? {
        let t0 = title
        let a0 = artist
        let tClean = Self.cleanTitle(t0)
        let aClean = Self.cleanArtist(a0)

        let queries: [String] = [
            #"track:"\#(t0)" artist:"\#(a0)""#,
            #"track:"\#(tClean)" artist:"\#(aClean)""#,
            #""\#(t0)" artist:"\#(a0)""#,
            #""\#(tClean)" artist:"\#(aClean)""#,
            #"track:"\#(t0)""#,
            #"track:"\#(tClean)""#
        ]

        var best: (Track, Int)?

        for q in queries {
            if let candidate = try await searchOnce(
                q: q,
                market: market,
                token: token
            ) {
                let score = Self.score(
                    candidate: candidate,
                    targetTitle: t0,
                    targetArtist: a0
                )
                if best == nil || score > best!.1 { best = (candidate, score) }
                if score >= 90 { break }
            }
        }
        return best?.0
    }

    private func searchOnce(q: String, market: String, token: String)
        async throws -> Track? {
        var comps = URLComponents(
            url: base.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            .init(name: "q", value: q),
            .init(name: "type", value: "track"),
            .init(name: "limit", value: "5"),
            .init(name: "market", value: market)
        ]
        var req = URLRequest(url: comps.url!)
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw ServiceError.api(-1)
        }
        guard (200...299).contains(http.statusCode) else {
            throw ServiceError.api(http.statusCode)
        }

        struct SearchResp: Decodable {
            struct Tracks: Decodable { let items: [Track] }
            let tracks: Tracks?
        }
        let decoded = try JSONDecoder().decode(SearchResp.self, from: data)
        return decoded.tracks?.items.first
    }

    private static func score(
        candidate: Track,
        targetTitle: String,
        targetArtist: String
    ) -> Int {
        let candTitle = normalize(candidate.name)
        let candArtists = normalize(
            candidate.artists.map(\.name).joined(separator: " ")
        )

        let tgtTitle = normalize(cleanTitle(targetTitle))
        let tgtArtist = normalize(cleanArtist(targetArtist))

        var s = 0
        if candTitle == tgtTitle {
            s += 70
        } else if candTitle.contains(tgtTitle) || tgtTitle.contains(candTitle) {
            s += 50
        }

        if candArtists.contains(tgtArtist) || tgtArtist.contains(candArtists) {
            s += 25
        }

        if candTitle.contains("karaoke") || candTitle.contains("tribute") {
            s -= 20
        }
        if candTitle.contains("live") && !tgtTitle.contains("live") { s -= 8 }
        if candTitle.contains("remix") && !tgtTitle.contains("remix") { s -= 6 }

        return min(max(s, 0), 100)
    }

    private static func cleanTitle(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(
            of: #"\s*\(feat\.[^)]*\)"#,
            with: "",
            options: .regularExpression
        )
        t = t.replacingOccurrences(
            of: #"\s*\[[^]]*\]"#,
            with: "",
            options: .regularExpression
        )
        t = t.replacingOccurrences(
            of: #"\s*\(Remaster(ed)?[^)]*\)"#,
            with: "",
            options: .regularExpression
        )
        t = t.replacingOccurrences(
            of: #"\s*\-.*(Version|Edit|Mix).*"#,
            with: "",
            options: .regularExpression
        )
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanArtist(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: "&", with: "and")
        t = t.replacingOccurrences(
            of: #"\s+feat\..*$"#,
            with: "",
            options: .regularExpression
        )
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalize(_ s: String) -> String {
        let d = s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let collapsed = d.unicodeScalars.map {
            allowed.contains($0) ? Character($0) : " "
        }
        .reduce(into: "") { $0.append($1) }
        .replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespaces)
        return collapsed
    }
}

// MARK: - Minimal Spotify models
private struct Track: Decodable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
    let external_urls: [String: String]?
}
private struct Artist: Decodable { let name: String }
private struct Album: Decodable { let images: [Image] }
private struct Image: Decodable { let url: String }
