import SwiftUI

// MARK: - FoodJournalFilterMenu

/// Narrows the journal by status, or shows one of the world food rankings
/// in its place.
struct FoodJournalFilterMenu: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewModel: FoodViewModel

    var body: some View {
        Menu {
            Button("All", systemImage: self.isShowingAll ? "checkmark" : "line.3.horizontal.decrease.circle") {
                self.viewModel.select(nil)
            }

            ForEach(RestaurantStatus.allCases) { status in
                let isSelected = self.viewModel.selectedShowcase == nil && self.viewModel.selectedFilter == status
                Button(status.label, systemImage: isSelected ? "checkmark" : status.systemImage) {
                    self.viewModel.select(status)
                }
            }

            // Not narrowings of the journal, so they stand apart.
            Divider()

            ForEach(FoodShowcase.allCases) { showcase in
                let isSelected = self.viewModel.selectedShowcase == showcase
                Button(showcase.title, systemImage: isSelected ? "checkmark" : showcase.systemImage) {
                    self.viewModel.select(showcase)
                }
            }
        } label: {
            Image(
                systemName: self.viewModel.isNarrowed
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
            .symbolEffect(.bounce, value: self.selectionKey)
            .symbolEffectsRemoved(self.reduceMotion)
        }
        .accessibilityLabel("Filter restaurants")
        .accessibilityInputLabels(["Filter Restaurants", "Restaurant Filter", "Top Cuisines", "Top Gastro Cities"])
    }

    private var isShowingAll: Bool {
        !self.viewModel.isNarrowed
    }

    /// Changes with every choice, so the icon acknowledges each one.
    private var selectionKey: String {
        self.viewModel.selectedShowcase?.rawValue ?? self.viewModel.selectedFilter?.rawValue ?? "all"
    }
}
