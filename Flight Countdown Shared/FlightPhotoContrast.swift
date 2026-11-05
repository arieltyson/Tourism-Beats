import Foundation

/// The contrast arithmetic behind a card's scrim, following WCAG 2's
/// relative luminance and contrast ratio, which Apple's accessibility
/// guidance also uses.
enum FlightPhotoContrast {
    /// Relative luminance, from 0 for black to 1 for white.
    static func luminance(of color: FlightRGB) -> Double {
        func linear(_ component: Double) -> Double {
            component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// From 1:1 for identical colours to 21:1 for black and white.
    static func ratio(_ first: FlightRGB, _ second: FlightRGB) -> Double {
        let (a, b) = (luminance(of: first), luminance(of: second))
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// `top` drawn at `opacity` over `bottom`, blended as the screen does.
    static func blend(_ top: FlightRGB, over bottom: FlightRGB, opacity: Double) -> FlightRGB {
        func mix(_ t: Double, _ b: Double) -> Double { opacity * t + (1 - opacity) * b }
        return FlightRGB(red: mix(top.red, bottom.red), green: mix(top.green, bottom.green), blue: mix(top.blue, bottom.blue))
    }

    /// A colour after SwiftUI's `contrast(_:)`, which stretches each
    /// component away from mid-grey.
    static func adjusted(_ color: FlightRGB, contrast: Double) -> FlightRGB {
        func stretch(_ c: Double) -> Double { min(max((c - 0.5) * contrast + 0.5, 0), 1) }
        return FlightRGB(red: stretch(color.red), green: stretch(color.green), blue: stretch(color.blue))
    }

    /// The least opacity of `scrim` over `background` at which white text,
    /// drawn at `textOpacity`, reaches `target` contrast, capped at `maximum`.
    static func scrimOpacity(
        over background: FlightRGB,
        scrim: FlightRGB,
        textOpacity: Double,
        target: Double,
        maximum: Double
    ) -> Double {
        func contrast(at opacity: Double) -> Double {
            let shaded = blend(scrim, over: background, opacity: opacity)
            return ratio(blend(.white, over: shaded, opacity: textOpacity), shaded)
        }
        guard contrast(at: 0) < target else { return 0 }
        guard contrast(at: maximum) >= target else { return maximum }
        // Contrast only grows as the scrim darkens, so halving the interval
        // finds the least opacity that's enough.
        var (low, high) = (0.0, maximum)
        for _ in 0..<Self.searchSteps {
            let middle = (low + high) / 2
            if contrast(at: middle) >= target { high = middle } else { low = middle }
        }
        return high
    }

    /// Enough halvings to settle within a thousandth of full opacity.
    private static let searchSteps = 10
}
