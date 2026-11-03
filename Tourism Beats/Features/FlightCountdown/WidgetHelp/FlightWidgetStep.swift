import SwiftUI

/// The steps to put Flight Countdown on the Home Screen, in order.
enum FlightWidgetStep: Int, CaseIterable, Identifiable {
    case holdHomeScreen = 1
    case addWidget
    case search
    case chooseSize

    var id: Int { rawValue }

    var instruction: LocalizedStringKey {
        switch self {
        case .holdHomeScreen: "Touch and hold an empty area of your Home Screen."
        case .addWidget: "Tap **Edit**, then **Add Widget**."
        case .search: "Search for **Tourism Beats**."
        case .chooseSize: "Choose a size, then tap **Add Widget**."
        }
    }

    /// The step's number, drawn as a filled circle.
    var systemImage: String { "\(rawValue).circle.fill" }
}
