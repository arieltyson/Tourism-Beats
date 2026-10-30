import SwiftUI

// MARK: - MapSearchBar

/// A glass search field that floats over the map within thumb reach.
/// It only starts a search; typing happens on the search screen it opens.
struct MapSearchBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Label("Search cities or countries", systemImage: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .accessibilityAddTraits(.isSearchField)
        .accessibilityRemoveTraits(.isButton)
    }
}

#Preview {
    MapSearchBar {}
        .padding()
}
