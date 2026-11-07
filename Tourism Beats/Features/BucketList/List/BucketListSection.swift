import SwiftUI

// MARK: - BucketListSection

/// One of the list's two halves: places, or activities.
struct BucketListSection: View {
    let title: String
    let items: [BucketListItem]
    let viewModel: BucketListViewModel

    var body: some View {
        Section(self.title) {
            ForEach(self.items) { item in
                BucketListRow(item: item) {
                    self.viewModel.toggleCompletion(of: item)
                }
                .sensoryFeedback(.success, trigger: item.isCompleted) { _, isCompleted in
                    isCompleted
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        self.viewModel.delete(item)
                    }
                }
            }
        }
    }
}
