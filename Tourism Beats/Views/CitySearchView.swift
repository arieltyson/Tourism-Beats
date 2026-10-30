// CitySearchView.swift
// Tourism Beats
//
// Full-screen native search over the city catalog, presented
// from the map's search bar with the field kept within thumb reach.

import SwiftUI

// MARK: - CitySearchView

struct CitySearchView: View {
    let onCitySelected: (CityModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CitySearchViewModel
    @State private var isSearchActive = false

    /// The field ignores activation until the cover has finished presenting.
    private static let activationDelay: Duration = .milliseconds(400)

    init(cities: [CityModel], onCitySelected: @escaping (CityModel) -> Void) {
        self.onCitySelected = onCitySelected
        self._viewModel = State(initialValue: CitySearchViewModel(cities: cities))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: SpacingTokens.small) {
                    ForEach(self.viewModel.results, id: \.id) { city in
                        Button {
                            self.onCitySelected(city)
                        } label: {
                            CitySearchResultRow(
                                city: city,
                                searchText: self.viewModel.query
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, SpacingTokens.medium)
            }
            // A few results sit just above the field rather than stranded
            // at the top; a full list still scrolls from the top as usual.
            .defaultScrollAnchor(.bottom, for: .alignment)
            .scrollDismissesKeyboard(.immediately)
            .overlay {
                if self.viewModel.hasNoResults {
                    ContentUnavailableView.search(text: self.viewModel.query)
                }
            }
            .searchable(
                text: self.$viewModel.query,
                isPresented: self.$isSearchActive,
                placement: .toolbar,
                prompt: "Search cities or countries"
            )
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)

                // Shown only while the field is inactive; the active
                // field supplies its own close button.
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
                        self.dismiss()
                    }
                }
            }
            .task {
                try? await Task.sleep(for: Self.activationDelay)
                self.isSearchActive = true
            }
        }
        // Cancelling the active field closes the screen too.
        .onChange(of: self.isSearchActive) { wasActive, isActive in
            if wasActive, !isActive {
                self.dismiss()
            }
        }
    }
}
