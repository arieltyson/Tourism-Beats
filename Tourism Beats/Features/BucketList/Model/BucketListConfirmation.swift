import Foundation

// MARK: - BucketListConfirmation

/// What the centered card says after a place joins or leaves the list.
struct BucketListConfirmation: Identifiable, Equatable, Sendable {
    let id = UUID()
    let placeName: String
    let wasAdded: Bool

    var message: String {
        self.wasAdded
            ? "\(self.placeName) added to Bucket List"
            : "\(self.placeName) removed from Bucket List"
    }

    var systemImage: String {
        self.wasAdded ? "checkmark.circle.fill" : "minus.circle.fill"
    }
}
