import SwiftUI

extension GradientProvider {
    /// Themed families (sunset, oceanic, forest, twilight, assorted, golden ratio), indices 24 onward.
    static let themedGradients: [MeshGradient] = [
        // MARK: - Sunset

        // 24 – Sunset blaze
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkOrange, dkRed, dkPink,
                dkYellow, dkOrange, dkRed,
                dkPurple, dkIndigo, dkBlue
            ]
        ),
        // 25 – Sunset fade
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.7, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkYellow, dkOrange, dkRed,
                dkPink, dkPurple, dkIndigo,
                dkBlue, dkCyan, dkTeal
            ]
        ),

        // MARK: - Oceanic

        // 26 – Oceanic deep
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.6], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkTeal, dkCyan, dkBlue,
                dkMint, dkGreen, dkIndigo,
                dkBlue, dkCyan, dkBlack
            ]
        ),
        // 27 – Oceanic drift
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlue, dkIndigo, dkPurple,
                dkCyan, dkTeal, dkGreen,
                dkMint, dkBlue, dkCyan
            ]
        ),

        // MARK: - Forest

        // 28 – Forest canopy
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.2], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkOrange, dkYellow, dkGreen,
                dkGreen, dkTeal, dkBlue,
                dkIndigo, dkBlack, dkGreen
            ]
        ),

        // MARK: - Twilight (replaces pastel)

        // 29 – Twilight mist
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(hue: 0.78, saturation: 0.50, brightness: 0.35),
                dkMint,
                dkCyan,
                dkPink,
                Color(hue: 0.07, saturation: 0.50, brightness: 0.35),
                dkYellow,
                dkTeal,
                Color(hue: 0.60, saturation: 0.50, brightness: 0.35),
                dkBlue
            ]
        ),

        // MARK: - Assorted

        // 30 – Verdant dusk
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.7, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkMint, dkTeal, dkGreen,
                dkYellow, dkOrange, dkRed,
                dkPink, dkPurple, dkIndigo
            ]
        ),

        // MARK: - Golden Ratio

        // 31 – Ember core
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkRed, dkBlack,
                dkRed, dkOrange, dkRed,
                dkBlack, dkRed, dkBlack
            ]
        ),
        // 32 – Cyan diamond
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkCyan, dkBlack,
                dkCyan, dkIndigo, dkCyan,
                dkBlack, dkCyan, dkBlack
            ]
        ),
        // 33 – Nebula
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkPurple, dkPink, dkRed,
                dkIndigo, dkBlue, dkCyan,
                dkBlack, dkTeal, dkGreen
            ]
        )
    ]
}
