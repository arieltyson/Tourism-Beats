import SwiftUI

// MARK: - TripNotesSection

struct TripNotesSection: View {
    @Binding var notes: String

    var body: some View {
        Section {
            TextField(
                "Trip notes (optional)",
                text: self.$notes,
                axis: .vertical
            )
            .lineLimit(3 ... 8)
        } header: {
            Text("Notes")
        }
    }
}
