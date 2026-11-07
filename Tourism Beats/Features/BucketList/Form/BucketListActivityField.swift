import SwiftUI

// MARK: - BucketListActivityField

/// The activity, typed in a word or a sentence.
struct BucketListActivityField: View {
    @Bindable var form: BucketListFormViewModel
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Section {
            TextField("Skydiving, northern lights, a hot air balloon…", text: self.$form.activity, axis: .vertical)
                .focused(self.$isFocused)
                .submitLabel(.done)
                .onSubmit(self.onSubmit)
                .accessibilityLabel("Activity")
        } header: {
            Text("What do you want to do?")
        }
        .onAppear { self.isFocused = true }
    }
}
