//
//  GradientProvider.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 12/7/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct GradientProvider {
    static let gradients: [MeshGradient] = [
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .black, .black, .black,
                .blue, .blue, .blue,
                .green, .green, .green
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .red, .purple, .indigo,
                .orange, .white, .blue,
                .yellow, .green, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .cyan, .teal,
                .pink, .purple, .indigo,
                .yellow, .orange, .red
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .yellow, .orange, .red,
                .purple, .blue, .green,
                .mint, .cyan, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.4, 0.1], [1.0, 0.0],
                [0.1, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.6, 0.9], [1.0, 1.0]
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.7, 0.0], [1.0, 0.0],
                [0.2, 0.5], [0.5, 0.5], [0.8, 0.5],
                [0.0, 1.0], [0.4, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .indigo, .purple,
                .pink, .red, .orange,
                .yellow, .green, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .cyan, .blue, .purple,
                .pink, .red, .orange,
                .yellow, .green, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.6, 0.0], [1.0, 0.0],
                [0.3, 0.5], [0.5, 0.5], [0.9, 0.5],
                [0.0, 1.0], [0.7, 1.0], [1.0, 1.0]
            ],
            colors: [
                .mint, .green, .yellow,
                .orange, .red, .purple,
                .blue, .cyan, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .pink, .red, .orange,
                .yellow, .green, .blue,
                .indigo, .purple, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0]
            ],
            colors: [
                .teal, .cyan, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.4, 0.0], [1.0, 0.0],
                [0.1, 0.5], [0.5, 0.4], [0.9, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .black, .blue, .green,
                .cyan, .mint, .purple,
                .pink, .red, .orange
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .black, .black, .black,
                .blue, .blue, .blue,
                .green, .green, .green
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .red, .purple, .indigo,
                .orange, .white, .blue,
                .yellow, .green, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .cyan, .teal,
                .pink, .purple, .indigo,
                .yellow, .orange, .red
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .yellow, .orange, .red,
                .purple, .blue, .green,
                .mint, .cyan, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.4, 0.1], [1.0, 0.0],
                [0.1, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.6, 0.9], [1.0, 1.0]
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.7, 0.0], [1.0, 0.0],
                [0.2, 0.5], [0.5, 0.5], [0.8, 0.5],
                [0.0, 1.0], [0.4, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .indigo, .purple,
                .pink, .red, .orange,
                .yellow, .green, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .cyan, .blue, .purple,
                .pink, .red, .orange,
                .yellow, .green, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.6, 0.0], [1.0, 0.0],
                [0.3, 0.5], [0.5, 0.5], [0.9, 0.5],
                [0.0, 1.0], [0.7, 1.0], [1.0, 1.0]
            ],
            colors: [
                .mint, .green, .yellow,
                .orange, .red, .purple,
                .blue, .cyan, .teal
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .pink, .red, .orange,
                .yellow, .green, .blue,
                .indigo, .purple, .mint
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.6, 1.0], [1.0, 1.0]
            ],
            colors: [
                .teal, .cyan, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .green, .mint, .blue,
                .indigo, .purple, .pink,
                .red, .orange, .yellow
            ]
        ),
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.4, 0.0], [1.0, 0.0],
                [0.1, 0.5], [0.5, 0.4], [0.9, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .black, .blue, .green,
                .cyan, .mint, .purple,
                .pink, .red, .orange
            ]
        )
    ]
}
