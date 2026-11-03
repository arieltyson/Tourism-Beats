import SwiftUI

/// Finds an airport by city, name, or code.
///
/// Results are grouped by the city they serve, so a city with several
/// airports lists them all together.
struct AirportPicker: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let selection: Airport?
    var directory: AirportDirectory = .bundled
    let onSelect: (Airport) -> Void

    @State private var query = ""
    @State private var groups: [AirportGroup] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let typedCode = DirectoryMatch.normalized(query).uppercased()
        let offersUnlisted = Airport.isCode(typedCode) && directory.airport(code: typedCode) == nil
        List {
            if offersUnlisted {
                Section {
                    FlightPickerUnlistedButton(code: typedCode) { choose(.unlisted(code: typedCode)) }
                } footer: {
                    Text("You’ll choose its time zone yourself.")
                }
            }
            ForEach(groups) { group in
                Section("\(group.city), \(group.countryName)") {
                    ForEach(group.airports) { airport in
                        Button {
                            choose(airport)
                        } label: {
                            FlightPickerRow(title: airport.name, detail: airport.code, isSelected: airport == selection)
                        }
                        .accessibilityAddTraits(airport == selection ? .isSelected : [])
                    }
                }
            }
        }
        .overlay {
            if query.isEmpty {
                ContentUnavailableView(
                    "Find an Airport", systemImage: "magnifyingglass",
                    description: Text("Search by city, airport name, or code.")
                )
            } else if groups.isEmpty, !isSearching, !offersUnlisted {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City, airport, or code")
        .searchFocused($isSearchFocused)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isSearchFocused = true }
        .task(id: query) {
            isSearching = true
            defer { isSearching = false }
            guard (try? await Task.sleep(for: FlightCountdownTokens.searchDebounce)) != nil else { return }
            groups = await directory.groups(matching: query)
        }
    }

    private func choose(_ airport: Airport) {
        onSelect(airport)
        dismiss()
    }
}
