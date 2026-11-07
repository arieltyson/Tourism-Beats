import SwiftData
import SwiftUI

// MARK: - BucketListView

/// The places to visit and the things to do, someday.
struct BucketListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \BucketListItem.dateAdded) private var items: [BucketListItem]
    @State private var isAdding = false

    var body: some View {
        // The view model holds no state of its own, only the rules for
        // changing the list, so a fresh one per update costs nothing.
        let viewModel = BucketListViewModel(modelContext: self.modelContext)
        let places = BucketListViewModel.places(in: self.items)
        let activities = BucketListViewModel.activities(in: self.items)

        Group {
            if self.items.isEmpty {
                BucketListEmptyState()
            } else {
                List {
                    if !places.isEmpty {
                        BucketListSection(title: "Places to Visit", items: places, viewModel: viewModel)
                    }

                    if !activities.isEmpty {
                        BucketListSection(title: "Activities to Do", items: activities, viewModel: viewModel)
                    }
                }
                .animation(self.reduceMotion ? nil : AnimationTokens.snappy, value: self.items.map(\.isCompleted))
            }
        }
        .navigationTitle("Bucket List")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add to Bucket List", systemImage: "plus") {
                    self.isAdding = true
                }
                .accessibilityInputLabels(["Add", "Add to Bucket List", "New Item"])
            }
        }
        .sheet(isPresented: self.$isAdding) {
            AddBucketListItemView()
        }
    }
}
