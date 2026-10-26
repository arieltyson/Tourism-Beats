import SwiftUI

enum GradientProvider {
    // MARK: - Dark Palette

    /// Rich, dark-skewing colors that preserve hue identity while ensuring
    /// >= 4.5 : 1 contrast ratio for white foreground text (WCAG AA).
    /// Brightness values stay between 0.25–0.50 so every mesh gradient
    /// reads as a moody, high-contrast backdrop.

    static let dkBlack = Color(hue: 0.00, saturation: 0.00, brightness: 0.06)
    static let dkRed = Color(hue: 0.00, saturation: 0.85, brightness: 0.40)
    static let dkOrange = Color(hue: 0.07, saturation: 0.85, brightness: 0.42)
    static let dkYellow = Color(hue: 0.12, saturation: 0.80, brightness: 0.42)
    static let dkGreen = Color(hue: 0.35, saturation: 0.80, brightness: 0.32)
    static let dkMint = Color(hue: 0.45, saturation: 0.70, brightness: 0.34)
    static let dkTeal = Color(hue: 0.50, saturation: 0.80, brightness: 0.32)
    static let dkCyan = Color(hue: 0.52, saturation: 0.80, brightness: 0.36)
    static let dkBlue = Color(hue: 0.60, saturation: 0.85, brightness: 0.38)
    static let dkIndigo = Color(hue: 0.72, saturation: 0.80, brightness: 0.34)
    static let dkPurple = Color(hue: 0.78, saturation: 0.75, brightness: 0.36)
    static let dkPink = Color(hue: 0.92, saturation: 0.70, brightness: 0.38)

    // MARK: - Gradients

    /// Every backdrop in a stable order; city pages derive an index from it,
    /// so new gradients are only ever appended.
    static let gradients: [MeshGradient] = signatureGradients + themedGradients
}
