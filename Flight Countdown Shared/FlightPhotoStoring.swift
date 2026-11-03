import CoreGraphics
import Foundation

/// Keeps the photos chosen for flights' cards, each under its own
/// ``FlightCardPhoto/id``.
protocol FlightPhotoStoring: Sendable {
    /// The photo, downsampled so its longer side is at most `maximumPixelSize`.
    func image(for id: UUID, maximumPixelSize: Int) async -> CGImage?
    func save(_ data: Data, for id: UUID) async throws
    func remove(for id: UUID) async throws
}
