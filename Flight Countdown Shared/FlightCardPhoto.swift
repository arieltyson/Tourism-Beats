import Foundation

/// One photo on a flight's card, and how it's framed there.
struct FlightCardPhoto: Codable, Hashable, Identifiable, Sendable {
    /// Names the stored photo file.
    var id: UUID = UUID()
    /// The library item the photo came from, so it shows as chosen when the
    /// photo picker opens again. Never used to read the library itself.
    var sourceIdentifier: String?
    var framing: FlightPhotoFraming = .centered
}
