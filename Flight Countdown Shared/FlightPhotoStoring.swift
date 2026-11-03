import CoreGraphics
import Foundation

/// Keeps the photo chosen for each flight's card.
protocol FlightPhotoStoring: Sendable {
    /// The photo, downsampled so its longer side is at most `maximumPixelSize`.
    func image(for id: UUID, maximumPixelSize: Int) async -> CGImage?
    func save(_ data: Data, for id: UUID) async throws
    func remove(for id: UUID) async throws
}
