import SwiftUI

/// A neumorphic button style that renders a soft card and animates on press.
/// Uses system background so it adapts to light/dark automatically.
@available(*, deprecated, message: "Use GlassCard with .buttonStyle(.plain) instead")
struct NeumorphicButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let bg = Color(.systemBackground)
        let lightShadow = AppColors.neumorphicLight
        let darkShadow = AppColors.neumorphicDark

        return configuration.label
            .padding() // inner content padding
            .background(
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
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
