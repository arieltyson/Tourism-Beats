import SwiftUI

// MARK: - TripStayRecommendationsSection

/// A few hotels for a trip with none, of the kind its budget affords. It
/// appears only once there are hotels to show.
struct TripStayRecommendationsSection: View {
    let viewModel: TripStayRecommendationsViewModel

    var body: some View {
        if case let .loaded(stays) = self.viewModel.state {
            Section {
                ForEach(stays) { stay in
                    TripStayRecommendationRow(
                        stay: stay,
                        isSelected: self.viewModel.isSelected(stay),
                        onToggle: { self.viewModel.toggle(stay) }
                    )
                }
            } header: {
                Text("Where to Stay")
            } footer: {
                Text(self.footer)
            }
        }
    }

    private var footer: String {
        guard let hotelClass = self.viewModel.hotelClass,
              let nightly = self.viewModel.nightlyBudget,
              let currencyCode = self.viewModel.currencyCode
        else {
            return "Pick one to make it your hotel, or keep looking."
        }
        let rate = nightly.formatted(.budget(currencyCode))
        return "\(hotelClass.searchQuery) for your budget of about \(rate) a night, "
            + "from typical prices in \(self.viewModel.cityName). Check rates before you book."
    }
}
