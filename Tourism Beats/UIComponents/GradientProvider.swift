import SwiftUI

struct GradientProvider {
    static let gradients: [MeshGradient] = [
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .black, .black,
                .blue, .blue, .blue,
                .green, .green, .green,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .cyan, .pink, .indigo,
                .yellow, .teal, .red,
                .purple, .blue, .orange,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .blue, .cyan, .teal,
                .pink, .purple, .indigo,
                .yellow, .orange, .red,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .yellow, .orange, .red,
                .purple, .blue, .green,
                .mint, .cyan, .teal,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .blue, .blue, .blue,
                .black, .black, .black,
                .red, .red, .red,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .teal, .teal, .teal,
                .blue, .blue, .blue,
                .black, .black, .black,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .cyan, .blue, .purple,
                .pink, .red, .orange,
                .yellow, .green, .teal,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .cyan, .cyan,
                .cyan, .black, .mint,
                .mint, .mint, .black,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink, .red, .orange,
                .yellow, .green, .blue,
                .indigo, .purple, .mint,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0],
            ],
            colors: [
                .teal, .cyan, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .cyan, .cyan,
                .cyan, .black, .pink,
                .pink, .pink, .black,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .indigo, .indigo, .black,
                .cyan, .black, .cyan,
                .black, .cyan, .indigo,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .red, .purple, .indigo,
                .orange, .blue, .blue,
                .yellow, .green, .mint,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .blue, .cyan, .teal,
                .pink, .purple, .indigo,
                .yellow, .orange, .red,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .yellow, .orange, .red,
                .purple, .blue, .green,
                .mint, .cyan, .teal,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .indigo, .indigo, .indigo,
                .black, .cyan, .black,
                .indigo, .black, .cyan,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .indigo, .indigo,
                .black, .red, .indigo,
                .black, .black, .red,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .cyan, .blue, .purple,
                .pink, .red, .orange,
                .yellow, .green, .teal,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .black, .black,
                .cyan, .cyan, .black,
                .red, .red, .cyan,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink, .red, .orange,
                .yellow, .green, .blue,
                .indigo, .purple, .mint,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0],
            ],
            colors: [
                .teal, .cyan, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink, .pink, .pink,
                .black, .indigo, .pink,
                .black, .black, .indigo,
            ]
        ),

        // New "Sunset" Theme Gradients
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .orange, .red, .pink,
                .yellow, .orange, .red,
                .purple, .indigo, .blue,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.7, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .yellow, .orange, .red,
                .pink, .purple, .indigo,
                .blue, .cyan, .teal,
            ]
        ),

        // New "Oceanic" Theme Gradients
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.6], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .teal, .cyan, .blue,
                .mint, .green, .indigo,
                .blue, .cyan, .black,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .blue, .indigo, .purple,
                .cyan, .teal, .green,
                .mint, .blue, .cyan,
            ]
        ),

        // New "Forest" Theme Gradients
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.4, 0.1], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.6, 0.9], [1.0, 1.0],
            ],
            colors: [
                .green, .teal, .mint,
                .yellow, .green, .blue,
                .black, .green, .indigo,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.2], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .orange, .yellow, .green,
                .green, .teal, .blue,
                .indigo, .black, .green,
            ]
        ),

        // New "Pastel" Theme Gradients
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(red: 0.9, green: 0.8, blue: 1.0), .mint, .cyan,
                .pink, Color(red: 1.0, green: 0.9, blue: 0.8), .yellow,
                .teal, Color(red: 0.8, green: 0.9, blue: 1.0), .blue,
            ]
        ),

        // New "Vibrant" & "Neon" Theme Gradients
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.1], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink, .red, .orange,
                .yellow, .green, .mint,
                .cyan, .blue, .purple,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.2, 0.1], [1.0, 0.0],
                [0.1, 0.5], [0.5, 0.5], [0.9, 0.5],
                [0.0, 1.0], [0.8, 0.9], [1.0, 1.0],
            ],
            colors: [
                .red, .orange, .yellow,
                .purple, .black, .green,
                .blue, .indigo, .pink,
            ]
        ),

        // More Assorted Mixes
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.7, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .mint, .teal, .green,
                .yellow, .orange, .red,
                .pink, .purple, .indigo,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .black, .red, .black,
                .red, .orange, .red,
                .black, .red, .black,
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .purple, .pink, .red,
                .indigo, .blue, .cyan,
                .black, .teal, .green,
            ]
        ),
    ]
}
