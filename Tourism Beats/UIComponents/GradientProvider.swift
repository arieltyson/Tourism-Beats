import SwiftUI

enum GradientProvider {
    // MARK: - Dark Palette

    /// Rich, dark-skewing colors that preserve hue identity while ensuring
    /// >= 4.5 : 1 contrast ratio for white foreground text (WCAG AA).
    /// Brightness values stay between 0.25–0.50 so every mesh gradient
    /// reads as a moody, high-contrast backdrop.

    private static let dkBlack = Color(hue: 0.00, saturation: 0.00, brightness: 0.06)
    private static let dkRed = Color(hue: 0.00, saturation: 0.85, brightness: 0.40)
    private static let dkOrange = Color(hue: 0.07, saturation: 0.85, brightness: 0.42)
    private static let dkYellow = Color(hue: 0.12, saturation: 0.80, brightness: 0.42)
    private static let dkGreen = Color(hue: 0.35, saturation: 0.80, brightness: 0.32)
    private static let dkMint = Color(hue: 0.45, saturation: 0.70, brightness: 0.34)
    private static let dkTeal = Color(hue: 0.50, saturation: 0.80, brightness: 0.32)
    private static let dkCyan = Color(hue: 0.52, saturation: 0.80, brightness: 0.36)
    private static let dkBlue = Color(hue: 0.60, saturation: 0.85, brightness: 0.38)
    private static let dkIndigo = Color(hue: 0.72, saturation: 0.80, brightness: 0.34)
    private static let dkPurple = Color(hue: 0.78, saturation: 0.75, brightness: 0.36)
    private static let dkPink = Color(hue: 0.92, saturation: 0.70, brightness: 0.38)

    // MARK: - Gradients

    static let gradients: [MeshGradient] = [
        // 0 – Deep ocean
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkBlack, dkBlack,
                dkBlue, dkBlue, dkBlue,
                dkGreen, dkGreen, dkGreen
            ]
        ),
        // 1 – Aurora
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkCyan, dkPink, dkIndigo,
                dkYellow, dkTeal, dkRed,
                dkPurple, dkBlue, dkOrange
            ]
        ),
        // 2 – Prismatic
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlue, dkCyan, dkTeal,
                dkPink, dkPurple, dkIndigo,
                dkYellow, dkOrange, dkRed
            ]
        ),
        // 3 – Spectrum
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkYellow, dkOrange, dkRed,
                dkPurple, dkBlue, dkGreen,
                dkMint, dkCyan, dkTeal
            ]
        ),
        // 4 – Flag
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlue, dkBlue, dkBlue,
                dkBlack, dkBlack, dkBlack,
                dkRed, dkRed, dkRed
            ]
        ),
        // 5 – Deep teal
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkTeal, dkTeal, dkTeal,
                dkBlue, dkBlue, dkBlue,
                dkBlack, dkBlack, dkBlack
            ]
        ),
        // 6 – Rainbow dim
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkCyan, dkBlue, dkPurple,
                dkPink, dkRed, dkOrange,
                dkYellow, dkGreen, dkTeal
            ]
        ),
        // 7 – Cyber mint
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkCyan, dkCyan,
                dkCyan, dkBlack, dkMint,
                dkMint, dkMint, dkBlack
            ]
        ),
        // 8 – Spectrum sweep
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkPink, dkRed, dkOrange,
                dkYellow, dkGreen, dkBlue,
                dkIndigo, dkPurple, dkMint
            ]
        ),
        // 9 – Cool flow
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkTeal, dkCyan, dkBlue,
                dkIndigo, dkPurple, dkPink,
                dkRed, dkOrange, dkYellow
            ]
        ),
        // 10 – Forest glow
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkGreen, dkMint, dkBlue,
                dkIndigo, dkPurple, dkPink,
                dkRed, dkOrange, dkYellow
            ]
        ),
        // 11 – Neon grid
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkCyan, dkCyan,
                dkCyan, dkBlack, dkPink,
                dkPink, dkPink, dkBlack
            ]
        ),
        // 12 – Deep indigo
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkIndigo, dkIndigo, dkBlack,
                dkCyan, dkBlack, dkCyan,
                dkBlack, dkCyan, dkIndigo
            ]
        ),
        // 13 – Warm dusk
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkRed, dkPurple, dkIndigo,
                dkOrange, dkBlue, dkBlue,
                dkYellow, dkGreen, dkMint
            ]
        ),
        // 14 – Prismatic II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlue, dkCyan, dkTeal,
                dkPink, dkPurple, dkIndigo,
                dkYellow, dkOrange, dkRed
            ]
        ),
        // 15 – Spectrum II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkYellow, dkOrange, dkRed,
                dkPurple, dkBlue, dkGreen,
                dkMint, dkCyan, dkTeal
            ]
        ),
        // 16 – Void indigo
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkIndigo, dkIndigo, dkIndigo,
                dkBlack, dkCyan, dkBlack,
                dkIndigo, dkBlack, dkCyan
            ]
        ),
        // 17 – Ember night
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkIndigo, dkIndigo,
                dkBlack, dkRed, dkIndigo,
                dkBlack, dkBlack, dkRed
            ]
        ),
        // 18 – Rainbow dim II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkCyan, dkBlue, dkPurple,
                dkPink, dkRed, dkOrange,
                dkYellow, dkGreen, dkTeal
            ]
        ),
        // 19 – Midnight flash
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkBlack, dkBlack, dkBlack,
                dkCyan, dkCyan, dkBlack,
                dkRed, dkRed, dkCyan
            ]
        ),
        // 20 – Spectrum sweep II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkPink, dkRed, dkOrange,
                dkYellow, dkGreen, dkBlue,
                dkIndigo, dkPurple, dkMint
            ]
        ),
        // 21 – Cool flow II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkTeal, dkCyan, dkBlue,
                dkIndigo, dkPurple, dkPink,
                dkRed, dkOrange, dkYellow
            ]
        ),
        // 22 – Forest glow II
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkGreen, dkMint, dkBlue,
                dkIndigo, dkPurple, dkPink,
                dkRed, dkOrange, dkYellow
            ]
        ),
        // 23 – Pink void
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                dkPink, dkPink, dkPink,
                dkBlack, dkIndigo, dkPink,
                dkBlack, dkBlack, dkIndigo
            ]
        ),

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
