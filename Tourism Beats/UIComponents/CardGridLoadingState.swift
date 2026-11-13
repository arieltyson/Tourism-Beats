import SwiftUI

// MARK: - CardGridLoadingState

/// Placeholder cards filling a guide's grid while it loads.
///
/// The cards pulse together from one animation of their fill, rather than
/// each card running its own and fading as a layer, so a loading page costs
/// little to draw while it's swiped past. With Reduce Motion they hold still.
struct CardGridLoadingState: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PhaseAnimator(self.reduceMotion ? [true] : [true, false]) { isBright in
            FillingCardGrid { _ in
                RoundedRectangle(cornerRadius: GuideCardTokens.cornerRadius, style: .continuous)
                    .fill(
                        AppColors.surfaceSecondary.opacity(
                            isBright
                                ? GuideCardTokens.placeholderBrightOpacity
                                : GuideCardTokens.placeholderDimOpacity
                        )
                    )
            }
        } animation: { _ in
            GuideCardTokens.placeholderPulse
        }
        .accessibilityHidden(true)
    }
}
