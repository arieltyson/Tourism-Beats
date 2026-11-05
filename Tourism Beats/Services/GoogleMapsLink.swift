import Foundation

// MARK: - GoogleMapsLink

/// Builds Google Maps links, which open the Google Maps app when it's
/// installed and the website otherwise.
enum GoogleMapsLink {
    /// A search for a place described by its parts, such as its name,
    /// address, city, and country. Empty parts are skipped, as are parts an
    /// earlier one already says, such as a city already in the address;
    /// returns `nil` when nothing is left to search for.
    ///
    /// Name a place's city and country, not only its street: Google picks
    /// the best-known match for what it's given, so "Blue Crab Restaurant,
    /// Robinson Street" opens a Blue Crab in Victoria, Canada rather than the
    /// one in Scarborough, Tobago.
    static func searchURL(for parts: [String?]) -> URL? {
        var kept: [String] = []
        for part in parts.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }) where !part.isEmpty {
            // Whole pieces only: an address ending ", Vancouver" says the city,
            // but a restaurant called "Paris Bistro" doesn't say "Paris".
            let said = kept.flatMap { $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
            if !said.contains(where: { $0.localizedCaseInsensitiveCompare(part) == .orderedSame }) {
                kept.append(part)
            }
        }
        let query = kept.joined(separator: ", ")

        guard !query.isEmpty else { return nil }

        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }
}
