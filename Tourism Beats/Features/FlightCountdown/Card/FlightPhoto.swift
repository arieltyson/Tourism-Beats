import CoreGraphics
import Foundation

/// A photo ready for a card: re-encoded for storage, decoded for display.
struct FlightPhoto: Sendable {
    let data: Data
    let image: CGImage
}
