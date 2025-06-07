import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicRecommendationViewModel: ObservableObject {
    @Published var songTitle: String = "Loading..."
    @Published var artistName: String = ""
    @Published var songImage: URL?
    @Published var isMusicFeatureAvailable: Bool = true

    let city: CityModel
    private let musicService: MusicServiceProtocol
    private var hasRequestedMusicAccess = false

    init(city: CityModel, musicService: MusicServiceProtocol = MusicService()) {
        self.city = city
        self.musicService = musicService
    }

    func requestAccessAndLoadTopSong() async {
        // Only show the permission pop-up once per session
        guard !hasRequestedMusicAccess else { return }

        let status = await MusicAuthorization.request()
        self.hasRequestedMusicAccess = true

        if status == .authorized {
            self.isMusicFeatureAvailable = true
            await fetchTopSongUsingDevToken()
        } else {
            self.isMusicFeatureAvailable = false
            self.songTitle = "Music Access Required"
            self.artistName =
                "Please grant permission in Settings to use this feature."
            self.songImage = nil
        }
    }

    private func fetchTopSongUsingDevToken() async {
        guard !city.country.code.isEmpty else {
            self.songTitle = "Country Info Missing"
            self.artistName = ""
            return
        }

        self.songTitle = "Loading Top Song..."
        self.artistName = "for \(city.country.name)"
        self.songImage = nil

        do {
            let appSong = try await musicService.fetchTopSong(
                countryCode: city.country.code
            )
            self.songTitle = appSong.title
            self.artistName = appSong.artistName
            self.songImage = appSong.artworkURL
        } catch let error as MusicService.MusicServiceError {
            handle(error: error)
        } catch {
            self.songTitle = "An Unexpected Error Occurred"
            self.artistName = "Please try again later."
            print("Generic error fetching top song data: \(error)")
        }
    }

    private func handle(error: MusicService.MusicServiceError) {
        switch error {
        case .tokenGenerationError:
            self.songTitle = "Authentication Error"
            self.artistName = "Could not generate developer token."
        case .noSongFoundInChart:
            self.songTitle = "Top Chart Unavailable"
            self.artistName = "No chart found for \(city.country.name)."
        case .apiError(let statusCode):
            self.songTitle = "API Error"
            self.artistName = "Could not connect (Code: \(statusCode))."
        default:
            self.songTitle = "Song Unavailable"
            self.artistName = "An error occurred while fetching."
        }
        print("MusicServiceError fetching top song: \(error)")
    }
}
