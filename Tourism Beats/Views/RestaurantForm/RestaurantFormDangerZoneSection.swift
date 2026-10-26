import SwiftUI

// MARK: - RestaurantFormDangerZoneSection

/// Deletes the restaurant after confirmation.
struct RestaurantFormDangerZoneSection: View {
    let onDelete: () -> Void

    var body: some View {
        Section {
            Button("Delete Restaurant", role: .destructive) {
                self.onDelete()
            }
        } header: {
            Text("Danger Zone")
        }
    }
}
