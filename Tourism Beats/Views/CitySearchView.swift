// CitySearchView.swift
// Tourism Beats
//
// Full-screen native search over the city catalog, presented
// from the map's search bar with the field kept within thumb reach.

import SwiftUI

// MARK: - CitySearchView

/// Presented without a presentation animation (see `WorldView`), so the field
/// is focused from the first frame; the screen fades itself in over the map
/// as the keyboard rises, and fades out again when search is cancelled.
struct CitySearchView: View {
    let onCitySelected: (CityModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CitySearchViewModel
    @State private var isSearchActive = false
    @State private var isShowing = false

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
            .opacity(self.isShowing ? 1 : 0)
            .containerBackground(.clear, for: .navigation)
            .searchable(
                text: self.$viewModel.query,
                isPresented: self.$isSearchActive,
                placement: .toolbar,
                prompt: "Search cities or countries"
            )
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
            // Fades out with the screen, so the idle field doesn't linger
            // over the tab bar once search is cancelled.
            .toolbarVisibility(self.isShowing ? .visible : .hidden, for: .bottomBar)
            .onAppear {
                self.isSearchActive = true
                withAnimation(.smooth) {
                    self.isShowing = true
                }
            }
        }
        .presentationBackground {
            Rectangle()
                .fill(.background)
                .opacity(self.isShowing ? 1 : 0)
        }
        // The field's own close button cancels search, which closes the screen.
        .onChange(of: self.isSearchActive) { wasActive, isActive in
            if wasActive, !isActive {
                self.close()
            }
        }
    }

    private func close() {
        withAnimation(.smooth) {
            self.isShowing = false
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.dismiss()
            }
        }
    }
}
