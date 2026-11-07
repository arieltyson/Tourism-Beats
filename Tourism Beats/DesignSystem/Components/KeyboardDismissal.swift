import SwiftUI
import UIKit

// MARK: - KeyboardDismissalModifier

/// The app's one way to put the keyboard away, for any screen that types.
///
/// A Hide Keyboard button rides above the keyboard, and a swipe down the
/// screen's content lowers it too. The button ends editing wherever it is,
/// so a screen's fields need no wiring of their own.
struct KeyboardDismissalModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Hide Keyboard", systemImage: "keyboard.chevron.compact.down") {
                        Self.endEditing()
                    }
                    .accessibilityInputLabels(["Hide Keyboard", "Dismiss Keyboard", "Done"])
                }
            }
    }

    /// Ends editing in whichever field has the keyboard.
    ///
    /// SwiftUI can only release focus through each field's own focus state,
    /// and focus bound on a container doesn't reach the field inside it, so
    /// this asks the app to end editing wherever focus is.
    @MainActor
    private static func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    /// Gives the screen the app's ways to put the keyboard away: a Hide
    /// Keyboard button above it, and a swipe down the content.
    func keyboardDismissal() -> some View {
        self.modifier(KeyboardDismissalModifier())
    }
}
