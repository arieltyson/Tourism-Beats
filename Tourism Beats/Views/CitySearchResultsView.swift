import SwiftUI

// MARK: - CitySearchResultsView

/// Search results shown over the map while the search field is active.
/// A few results sit just above the field rather than stranded at the top;
/// a full list scrolls from the top as usual.
struct CitySearchResultsView: View {
    let viewModel: CitySearchViewModel
    let onCitySelected: (CityModel) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: SpacingTokens.small) {
                ForEach(self.viewModel.results, id: \.id) { city in
                    Button {
                        self.onCitySelected(city)
                    } label: {
                        CitySearchResultRow(city: city, searchText: self.viewModel.query)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.small)
        }
        .defaultScrollAnchor(.bottom, for: .alignment)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .overlay {
            if self.viewModel.hasNoResults {
                ContentUnavailableView.search(text: self.viewModel.query)
            }
        }
    }
}
