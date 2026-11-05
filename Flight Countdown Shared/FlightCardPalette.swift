import SwiftUI

/// Card tones, chosen so white text keeps at least 4.5:1 contrast on each.
enum FlightCardPalette {
    static let twilight = [
        Color(red: 0.06, green: 0.10, blue: 0.23),
        Color(red: 0.13, green: 0.13, blue: 0.32),
        Color(red: 0.23, green: 0.18, blue: 0.37),
    ]
    static let sunset = [
        Color(red: 0.24, green: 0.07, blue: 0.20),
        Color(red: 0.46, green: 0.13, blue: 0.24),
        Color(red: 0.66, green: 0.27, blue: 0.14),
    ]
    static let ocean = [
        Color(red: 0.02, green: 0.13, blue: 0.24),
        Color(red: 0.03, green: 0.24, blue: 0.36),
        Color(red: 0.05, green: 0.38, blue: 0.45),
    ]
    static let aurora = [
        Color(red: 0.04, green: 0.12, blue: 0.18),
        Color(red: 0.08, green: 0.36, blue: 0.32),
        Color(red: 0.30, green: 0.18, blue: 0.45),
    ]
    static let graphite = [
        Color(red: 0.09, green: 0.09, blue: 0.11),
        Color(red: 0.18, green: 0.18, blue: 0.21),
        Color(red: 0.28, green: 0.29, blue: 0.32),
    ]
}
