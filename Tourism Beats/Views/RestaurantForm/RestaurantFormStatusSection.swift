import SwiftUI

// MARK: - RestaurantFormStatusSection

/// Whether the restaurant is a wish or a visit.
struct RestaurantFormStatusSection: View {
    @Binding var status: RestaurantStatus

    var body: some View {
        Section("Status") {
            Picker("Status", selection: self.$status) {
                ForEach(RestaurantStatus.allCases) { restaurantStatus in
                    Label(restaurantStatus.label, systemImage: restaurantStatus.systemImage)
                        .tag(restaurantStatus)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
