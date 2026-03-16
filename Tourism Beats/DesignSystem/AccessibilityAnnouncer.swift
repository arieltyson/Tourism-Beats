import SwiftUI

/// Posts VoiceOver announcements for important navigation and discovery events.
@MainActor
enum AccessibilityAnnouncer {
    // MARK: - City Navigation

    static func announceCitySelected(_ cityName: String, country: String) {
        self.post("Selected \(cityName), \(country).")
    }

    static func announcePageChanged(to pageName: String) {
        self.post("Showing \(pageName) page.")
    }

    // MARK: - Music

    static func announceMusicPlaying(track: String, artist: String) {
        self.post("Now playing \(track) by \(artist).")
    }

    static func announceMusicStopped() {
        self.post("Music stopped.")
    }

    // MARK: - Advisories

    static func announceAdvisoryLoaded(city: String) {
        self.post("Travel advisories loaded for \(city).")
    }

    static func announceVisaInfo(status: String) {
        self.post("Visa status: \(status).")
    }

    // MARK: - Discovery

    static func announceDiscoveryLoaded(count: Int) {
        let label = count == 1
            ? "1 featured destination loaded."
            : "\(count) featured destinations loaded."
        self.post(label)
    }

    // MARK: - Search

    static func announceSearchResults(count: Int) {
        let label = count == 1 ? "1 result found." : "\(count) results found."
        self.post(label)
    }

    static func announceSearchCleared() {
        self.post("Search cleared.")
    }

    // MARK: - Private

    private static func post(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}
