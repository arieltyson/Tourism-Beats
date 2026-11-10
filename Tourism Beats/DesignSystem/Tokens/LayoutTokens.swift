import CoreGraphics

// MARK: - LayoutTokens

/// How much room content may take.
///
/// Layouts respond to the width they're given, never to the device's name.
/// Every iPhone in portrait, iPhone Duo's outer display included, is far
/// narrower than two panes, so it keeps the single-column layout it was
/// designed for. A width with room for two, such as iPhone Duo's unfolded
/// display, sets content side by side instead of stretching one column
/// across it.
///
/// Width alone decides, not shape: a stacked layout is taller than a
/// side-by-side one, so a rule that also asked for wider-than-tall would
/// keep whichever layout it started with.
enum LayoutTokens {
    /// A comfortable width for a column of cards or text.
    static let readableWidth: CGFloat = 680

    /// The narrowest a pane stays readable.
    static let paneWidth: CGFloat = 320

    /// The space between two panes.
    static let paneSpacing = SpacingTokens.large

    /// The narrowest width that holds two panes side by side.
    static let twoPaneWidth = paneWidth * 2 + paneSpacing

    /// Whether `width` has room for two panes side by side. No iPhone in
    /// portrait qualifies.
    static func fitsPanes(_ width: CGFloat) -> Bool {
        width >= self.twoPaneWidth
    }
}
