import SwiftUI

// MARK: - RestaurantFormNotesSection

/// Free-form notes.
struct RestaurantFormNotesSection: View {
    @Binding var notes: String
    var focusedField: FocusState<RestaurantFormField?>.Binding

    var body: some View {
        Section("Notes") {
            TextField("Add notes (optional)", text: self.$notes, axis: .vertical)
                .lineLimit(3 ... 8)
                .focused(self.focusedField, equals: .notes)
        }
    }
}
