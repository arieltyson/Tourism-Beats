import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - SpotifyHandoffTests

struct SpotifyHandoffTests {
    @Test func searchesForTheTitleAndArtist() throws {
        let handoff = try #require(SpotifyHandoff(title: "結び", artist: "Ayumu Imazu"))

        #expect(handoff.appURL.scheme == "spotify")
        #expect(handoff.webURL.host() == "open.spotify.com")
        #expect(handoff.webURL.path().hasPrefix("/search/"))
        #expect(handoff.appURL.absoluteString.removingPercentEncoding == "spotify:search:結び Ayumu Imazu")
    }

    @Test(arguments: [
        ("Song (feat. Someone)", "Artist", "Song Artist"),
        ("Song [Remastered 2011]", "Artist", "Song Artist"),
        ("(Intro)", "Artist", "(Intro) Artist"),
        ("  Spaced   Out  ", " Artist ", "Spaced Out Artist")
    ])
    func leavesOutExtrasThatRarelyMatch(title: String, artist: String, query: String) {
        #expect(SpotifyHandoff.query(title: title, artist: artist) == query)
    }

    @Test func slashesAndAmpersandsStayInsideTheSearch() throws {
        let handoff = try #require(SpotifyHandoff(title: "AC/DC & Co", artist: "Band"))

        #expect(handoff.webURL.pathComponents.count == 3)
        #expect(!handoff.appURL.absoluteString.contains("&"))
    }

    @Test func nothingToSearchForMakesNoHandoff() {
        #expect(SpotifyHandoff(title: " ", artist: "") == nil)
    }
}
