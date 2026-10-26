import SwiftUI

// MARK: - CityPageFrameModifier

/// Sizes one page of the city pager to the full screen and insets its content
/// by the bars' safe area.
///
/// Pages that stopped at the safe area left the strip behind the floating tab
/// bar to the next page, so its top showed through the glass. Full-height
/// pages keep neighbors off screen at rest, while each page's own content
/// still clears, and can scroll beneath, the navigation and tab bars.
struct CityPageFrameModifier: ViewModifier {
    let index: Int
    let barInsets: EdgeInsets

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.top, self.barInsets.top)
            .safeAreaPadding(.bottom, self.barInsets.bottom)
            .containerRelativeFrame([.horizontal, .vertical])
            .id(self.index)
    }
}

extension View {
    func cityPageFrame(index: Int, barInsets: EdgeInsets) -> some View {
        self.modifier(CityPageFrameModifier(index: index, barInsets: barInsets))
    }
}
