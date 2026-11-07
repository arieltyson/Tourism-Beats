import SwiftUI

// MARK: - BucketListActivityField

/// The activity, typed in a word or a sentence.
///
/// Long activities wrap onto more lines as they're typed. Return puts the
/// keyboard away rather than starting a new line; adding is the toolbar's.
struct BucketListActivityField: View {
    let form: BucketListFormViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        Section {
            TextField(
                "Skydiving, northern lights, a hot air balloon…",
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
        } header: {
            Text("What do you want to do?")
        }
        .onAppear { self.isFocused = true }
    }
}
