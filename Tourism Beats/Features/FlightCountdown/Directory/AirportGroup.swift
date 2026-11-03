import Foundation

/// Airports that serve one city, listed together in search results.
struct AirportGroup: Hashable, Identifiable, Sendable {
    let city: String
    let countryName: String
    let airports: [Airport]

    var id: String { "\(city)|\(countryName)" }
}
