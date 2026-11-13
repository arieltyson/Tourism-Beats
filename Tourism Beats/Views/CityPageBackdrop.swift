import SwiftUI

// MARK: - CityPageBackdrop

/// The full-screen gradient behind the city's pages, one for each page.
///
/// It changes once the pager settles rather than as a page crosses midway:
/// a changing backdrop redraws every glass card above it on each frame, which
/// is more than a frame can afford while those cards are also moving.
struct CityPageBackdrop: View {
    let city: CityModel
    let pageIndex: Int

    /// Spreads a city's pages across the gradients, so neighbors differ.
    private static let pageSeeds: [UInt] = [31, 47, 59, 71, 83]

    var body: some View {
        self.gradient
            .motionSensitiveAnimation(
                .easeInOut(duration: 0.4),
                reduced: .linear(duration: 0.01),
                value: self.pageIndex
            )
    }

    private var gradient: MeshGradient {
        let all = GradientProvider.gradients
        let base = UInt(bitPattern: self.city.id.hashValue)
        let multiplier = Self.pageSeeds[min(self.pageIndex, Self.pageSeeds.count - 1)]
        let seed = base &* multiplier
        return all[Int(seed % UInt(all.count))]
    }
}
