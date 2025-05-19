import SwiftUI

/// A container that wraps any content in a soft, adaptive neumorphic card
struct NeumorphicCard<Content: View>: View {
    @GestureState private var isPressed = false
    let cornerRadius: CGFloat
    let content: () -> Content

    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        let bg = Color(.systemBackground)
        let lightShadow = Color.white.opacity(0.7)
        let darkShadow = Color.black.opacity(0.2)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bg)
                // “Raised” when not pressed
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
            content()
                .padding()
        }
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.01)
                .updating($isPressed) { current, state, _ in
                    state = current
                }
        )
    }
}
