import Foundation

// MARK: - GoogleMapsLink

/// Builds Google Maps links, which open the Google Maps app when it's
/// installed and the website otherwise.
enum GoogleMapsLink {
    /// A search for a place described by its parts, such as its name,
    /// address, and city. Empty parts are skipped; returns `nil` when
    /// nothing is left to search for.
    static func searchURL(for parts: [String?]) -> URL? {
        let query = parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        guard !query.isEmpty else { return nil }

        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }
}
