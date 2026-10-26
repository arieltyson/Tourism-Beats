import SwiftUI

// MARK: - TripDayHeaderMenu

struct TripDayHeaderMenu: View {
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onSuggestActivities: (() -> Void)?
    let onDeleteDay: () -> Void

    var body: some View {
        if self.canDelete || self.onSuggestActivities != nil {
            Menu("Day Actions", systemImage: "ellipsis.circle") {
                Button("Add Activity", systemImage: "plus") {
                    self.onAddActivity()
                }

                if let onSuggestActivities {
                    Button("Suggest Activities", systemImage: "sparkles") {
                        onSuggestActivities()
                    }
                }

                if self.canDelete {
                    Button("Delete Day", systemImage: "trash", role: .destructive) {
                        self.onDeleteDay()
                    }
                }
            }
            .labelStyle(.iconOnly)
            .accessibilityInputLabels(["Day Actions", "More Day Actions"])
        }
    }
}
