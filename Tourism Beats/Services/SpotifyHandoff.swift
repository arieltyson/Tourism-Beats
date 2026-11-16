import Foundation

// MARK: - SpotifyHandoff

/// The links that take a song from this app to Spotify.
///
/// The handoff opens Spotify's own search for the song, so it needs no
/// Spotify sign-in, developer key or network request, and it works for every
/// listener the moment they tap. The app link is tried first; the web link
/// covers listeners without the app, and still opens the app through its
/// universal link when it's installed.
struct SpotifyHandoff: Equatable, Sendable {
    /// Opens the search in the Spotify app.
    let appURL: URL

    /// Opens the search on the Spotify website.
    let webURL: URL

    /// Creates the links for a song, or `nil` when there's nothing to search for.
    init?(title: String, artist: String) {
        let query = Self.query(title: title, artist: artist)
        guard
            !query.isEmpty,
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
            let appURL = URL(string: "spotify:search:\(encoded)"),
            let webURL = URL(string: "https://open.spotify.com/search/\(encoded)")
        else { return nil }

        self.appURL = appURL
        self.webURL = webURL
    }

    /// The song's title and artist, as one search.
    ///
    /// Bracketed extras such as "(feat. …)" or "[Remastered]" are left out:
    /// they rarely match how Spotify titles the same recording.
    static func query(title: String, artist: String) -> String {
        let bracketed = /\s*[\(\[][^\)\]]*[\)\]]/
        let strippedTitle = title.replacing(bracketed, with: "")
        let cleanTitle = strippedTitle.allSatisfy(\.isWhitespace) ? title : strippedTitle
        return "\(cleanTitle) \(artist)"
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
