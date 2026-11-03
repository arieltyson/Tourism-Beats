import Foundation

/// A photo chosen in the photo picker, loaded only if the card doesn't
/// already have it.
struct FlightPhotoSource: Sendable {
    /// The library item's identifier, which matches a photo chosen before.
    let identifier: String?
    let load: @Sendable () async throws -> Data
}
