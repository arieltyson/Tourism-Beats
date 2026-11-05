import SwiftUI

// MARK: - FoodJournalFilterMenu

/// Narrows the journal by status, or shows the world's best cuisines in
/// its place.
struct FoodJournalFilterMenu: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewModel: FoodViewModel

    var body: some View {
        Menu {
            Button("All", systemImage: self.isShowingAll ? "checkmark" : "line.3.horizontal.decrease.circle") {
                self.viewModel.select(nil)
            }

            ForEach(RestaurantStatus.allCases) { status in
                let isSelected = !self.viewModel.showsTopCuisines && self.viewModel.selectedFilter == status
                Button(status.label, systemImage: isSelected ? "checkmark" : status.systemImage) {
                    self.viewModel.select(status)
                }
            }

            // Not a narrowing of the journal, so it stands apart.
            Divider()

            Button("Top Cuisines", systemImage: self.viewModel.showsTopCuisines ? "checkmark" : "trophy") {
                self.viewModel.selectTopCuisines()
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
        .accessibilityInputLabels(["Filter Restaurants", "Restaurant Filter", "Top Cuisines"])
    }

    private var isShowingAll: Bool {
        !self.viewModel.isNarrowed
    }

    /// Changes with every choice, so the icon acknowledges each one.
    private var selectionKey: String {
        self.viewModel.showsTopCuisines ? "topCuisines" : self.viewModel.selectedFilter?.rawValue ?? "all"
    }
}
