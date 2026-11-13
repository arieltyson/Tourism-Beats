import CoreGraphics
import SwiftUI

// MARK: - GuideCardTokens

/// The look of the activity and restaurant cards in a city's guides.
enum GuideCardTokens {
    static let cornerRadius: CGFloat = 24
    static let borderWidth: CGFloat = 1
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 10

    /// How strongly a loading placeholder's fill shows at the dim and bright
    /// ends of its pulse.
    static let placeholderDimOpacity = 0.24
    static let placeholderBrightOpacity = 0.48

    /// One half of the placeholders' pulse, dim to bright or back.
    static let placeholderPulse: Animation = .easeInOut(duration: 1)
}
