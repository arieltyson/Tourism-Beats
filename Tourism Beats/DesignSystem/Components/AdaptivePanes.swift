import SwiftUI

// MARK: - AdaptivePanes

/// Two groups of content, stacked on a phone and side by side where both
/// fit, as on iPhone Duo's unfolded display.
///
/// The stacked form is a plain `VStack`, so every phone lays out exactly as
/// it did before there were panes. The choice comes from the width offered,
/// not from a measured size, so it's right on the first pass, even inside a
/// `ViewThatFits`. Accessibility text sizes always stack, so text keeps its
/// full width. VoiceOver reads the leading pane first in either form.
struct AdaptivePanes<Leading: View, Trailing: View>: View {
    var alignment: VerticalAlignment = .center
    var stackSpacing: CGFloat = SpacingTokens.medium
    /// Whether each pane keeps its own height side by side, rather than
    /// stretching to the height there is.
    var panesHugContent = false
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: self.stackSpacing) {
                self.leading
                self.trailing
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: self.alignment, spacing: LayoutTokens.paneSpacing) {
                    self.leading
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: self.panesHugContent)
                    self.trailing
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: self.panesHugContent)
                }
                // Asks for exactly two panes' width, whatever the text inside
                // would like, so this form fits only where both panes do.
                .frame(minWidth: LayoutTokens.twoPaneWidth, idealWidth: LayoutTokens.twoPaneWidth, maxWidth: .infinity)

                VStack(spacing: self.stackSpacing) {
                    self.leading
                    self.trailing
                }
            }
        }
    }
}
