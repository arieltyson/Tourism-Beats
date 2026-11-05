import SwiftUI

// MARK: - TripPlanSection

/// Offers to fill a new trip's days with a suggested plan once it's added.
struct TripPlanSection: View {
    @Binding var suggestsPlan: Bool
    let cityName: String
    var stayName: String?

    var body: some View {
        Section {
            Toggle("Suggest a Plan", isOn: self.$suggestsPlan)
                .tint(AppColors.coral)
        } footer: {
            if let stayName {
                Text("Top sights and places to eat near \(stayName), for you to review.")
            } else {
                Text("Top sights and places to eat in \(self.cityName), for you to review.")
            }
        }
    }
}
