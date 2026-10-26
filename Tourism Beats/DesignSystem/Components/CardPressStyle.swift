import SwiftUI

// MARK: - CardPressStyle

/// Press feedback for buttons whose label is a whole card: the card dims and
/// settles slightly while pressed.
///
/// With Reduce Motion on, the card only dims, so a press is still visible
/// without any movement.
struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !self.reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(self.reduceMotion ? .none : AnimationTokens.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardPressStyle {
    static var cardPress: CardPressStyle { CardPressStyle() }
}
