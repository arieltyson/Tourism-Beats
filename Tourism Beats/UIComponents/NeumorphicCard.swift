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
            RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                .fill(bg)
                // “Raised” when not pressed
                .shadow(
                    color: self.isPressed ? darkShadow : lightShadow,
                    radius: self.isPressed ? 2 : 8,
                    x: self.isPressed ? 2 : -8,
                    y: self.isPressed ? 2 : -8
                )
                .shadow(
                    color: self.isPressed ? lightShadow : darkShadow,
                    radius: self.isPressed ? 2 : 8,
                    x: self.isPressed ? -2 : 8,
                    y: self.isPressed ? -2 : 8
                )
            self.content()
                .padding()
        }
        .scaleEffect(self.isPressed ? 0.97 : 1)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.6),
            value: self.isPressed
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.01)
                .updating(self.$isPressed) { current, state, _ in
                    state = current
                }
        )
    }
}
