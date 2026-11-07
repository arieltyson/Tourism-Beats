import SwiftUI

// MARK: - AddBucketListItemView

/// A sheet for adding a place to visit or an activity to do.
struct AddBucketListItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var form = BucketListFormViewModel()
    @State private var isChoosingCountry = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: self.$form.kind) {
                        ForEach(BucketListItemKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.systemImage)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch self.form.kind {
                case .place:
                    BucketListPlaceFields(form: self.form) {
                        self.isChoosingCountry = true
                    }
                case .activity:
                    BucketListActivityField(form: self.form, onSubmit: self.add)
                }
            }
            .navigationTitle("Add to Bucket List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", systemImage: "checkmark", action: self.add)
                        .disabled(!self.form.canAdd)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // Presented from here, not from the form's lazy rows.
            .sheet(isPresented: self.$isChoosingCountry) {
                BucketListPlacePicker(form: self.form)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func add() {
        guard self.form.add(to: BucketListViewModel(modelContext: self.modelContext)) else { return }
        self.dismiss()
    }
}
