import SwiftUI

// MARK: - BucketListActivityField

/// The activity, typed in a word or a sentence.
///
/// Long activities wrap onto more lines as they're typed, but Return adds
/// the activity, as the keyboard's checkmark promises, instead of starting a
/// new line. A swipe down the form puts the keyboard away too.
struct BucketListActivityField: View {
    let form: BucketListFormViewModel
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Section {
            TextField(
                "Skydiving, northern lights, a hot air balloon…",
                text: Binding(
                    get: { self.form.activity },
                    set: { text in
                        guard self.form.updateActivity(text) else { return }
                        // With nothing to add yet, Return just puts the keyboard away.
                        if self.form.canAdd {
                            self.onSubmit()
                        } else {
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
