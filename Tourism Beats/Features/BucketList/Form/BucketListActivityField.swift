import SwiftUI

// MARK: - BucketListActivityField

/// The activity, typed in a word or a sentence.
///
/// Long activities wrap onto more lines as they're typed. Return puts the
/// keyboard away rather than starting a new line; adding is the toolbar's.
/// The keyboard waits for a tap, so switching between a place and an
/// activity never throws it up unasked.
struct BucketListActivityField: View {
    let form: BucketListFormViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(
            "Skydiving, northern lights…",
            text: Binding(
                get: { self.form.activity },
                set: { text in
                    if self.form.updateActivity(text) {
                        self.isFocused = false
                    }
                }
            ),
            axis: .vertical
        )
        .focused(self.$isFocused)
        .submitLabel(.done)
        .accessibilityLabel("Activity")
    }
}
