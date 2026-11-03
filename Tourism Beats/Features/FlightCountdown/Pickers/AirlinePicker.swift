import SwiftUI

/// Finds an airline by name or code, or accepts any valid code typed in.
struct AirlinePicker: View {
    @Environment(\.dismiss) private var dismiss
    let selection: Airline?
    var directory: AirlineDirectory = .bundled
    let onSelect: (Airline) -> Void

    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let results = directory.results(matching: query)
        let typedCode = DirectoryMatch.normalized(query).uppercased()
        List {
            if Airline.isCode(typedCode), directory.airline(code: typedCode) == nil {
                Section {
                    FlightPickerUnlistedButton(code: typedCode) { choose(.unlisted(code: typedCode)) }
                } footer: {
                    Text("Not in the list? Use the two-character code on the booking.")
                }
            }
            ForEach(results) { airline in
                Button {
                    choose(airline)
                } label: {
                    FlightPickerRow(title: airline.name, detail: airline.code, isSelected: airline == selection)
                }
                .accessibilityAddTraits(airline == selection ? .isSelected : [])
            }
        }
        .overlay {
            if results.isEmpty, !Airline.isCode(typedCode) {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name or code")
        .searchFocused($isSearchFocused)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Airline")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isSearchFocused = selection == nil }
    }

    private func choose(_ airline: Airline) {
        onSelect(airline)
        dismiss()
    }
}
