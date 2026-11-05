import Foundation

// MARK: - WorldCuisine

/// One of the world's best-rated cuisines, shown with a dish it's loved for.
struct WorldCuisine: Identifiable, Hashable, Sendable {
    /// Its place in the ranking, from 1.
    let rank: Int
    let name: String
    let flag: String
    let signatureDish: String
    let imageURL: URL?

    var id: Int { self.rank }

    var accessibilityLabel: String {
        String(localized: "Number \(self.rank), \(self.name), known for \(self.signatureDish)")
    }
}
