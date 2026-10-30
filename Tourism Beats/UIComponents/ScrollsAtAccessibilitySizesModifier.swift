import SwiftUI

// MARK: - ScrollsAtAccessibilitySizesModifier

/// Lets a page that is sized to fit the screen scroll once accessibility text
/// sizes make its content taller than the screen.
struct ScrollsAtAccessibilitySizesModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if self.dynamicTypeSize.isAccessibilitySize {
            ScrollView(.vertical) {
                content
            }
            .scrollIndicators(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func scrollsAtAccessibilitySizes() -> some View {
        self.modifier(ScrollsAtAccessibilitySizesModifier())
    }
}
