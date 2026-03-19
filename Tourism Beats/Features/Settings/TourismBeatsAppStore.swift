import Foundation

enum TourismBeatsAppStore {
    static let appID = "6708221715"

    static let reviewURL: URL = {
        var components = URLComponents(
            string: "https://apps.apple.com/app/id\(Self.appID)"
        )
        components?.queryItems = [
            URLQueryItem(name: "action", value: "write-review")
        ]

        guard let url = components?.url else {
            preconditionFailure("Expected a valid App Store review URL.")
        }

        return url
    }()
}
