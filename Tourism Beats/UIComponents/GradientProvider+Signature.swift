import SwiftUI

extension GradientProvider {
    /// The original mesh backdrops, indices 0–23.
    static let signatureGradients: [MeshGradient] = [
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
        )
    ]
}
