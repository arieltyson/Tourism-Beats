/// A colour as sRGB-encoded components from 0 to 1, as it's composited on
/// screen.
struct FlightRGB: Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double

    static let white = Self(red: 1, green: 1, blue: 1)
    static let black = Self(red: 0, green: 0, blue: 0)
}
