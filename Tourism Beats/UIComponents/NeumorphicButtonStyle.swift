import SwiftUI

/// A neumorphic button style that renders a soft card and animates on press.
/// Uses system background so it adapts to light/dark automatically.
struct NeumorphicButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let bg = Color(.systemBackground)
        let lightShadow = Color.white.opacity(0.7)
        let darkShadow = Color.black.opacity(0.2)

        return configuration.label
            .padding()  // inner content padding
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bg)
                    // “raised” when not pressed, “inset” when pressed
                    .shadow(
                        color: isPressed ? darkShadow : lightShadow,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 2 : -8,
                        y: isPressed ? 2 : -8
                    )
                    .shadow(
                        color: isPressed ? lightShadow : darkShadow,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? -2 : 8,
                        y: isPressed ? -2 : 8
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.7),
                value: isPressed
            )
    }
}
