import SwiftUI

/// The background of a flight's card, in the app and on the Home Screen.
enum FlightCardTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case twilight
    case sunset
    case ocean
    case aurora
    case graphite
    /// A photo the person chose.
    case photo

    var id: Self { self }

    /// The designed backgrounds, in the order they're offered.
    static let gradients: [Self] = [.twilight, .sunset, .ocean, .aurora, .graphite]

    var title: LocalizedStringResource {
        switch self {
        case .twilight: "Twilight"
        case .sunset: "Sunset"
        case .ocean: "Ocean"
        case .aurora: "Aurora"
        case .graphite: "Graphite"
        case .photo: "Photo"
        }
    }

    /// Three tones from deepest to lightest, each dark enough for white text
    /// at 4.5:1 or better. A photo falls back to twilight until it loads.
    var palette: [Color] {
        switch self {
        case .twilight, .photo: FlightCardPalette.twilight
        case .sunset: FlightCardPalette.sunset
        case .ocean: FlightCardPalette.ocean
        case .aurora: FlightCardPalette.aurora
        case .graphite: FlightCardPalette.graphite
        }
    }
}
