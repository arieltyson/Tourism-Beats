import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, search, food, trips, settings

    static let primaryTabs: [AppTab] = [.home, .search, .food, .trips]

    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .food: "Food"
        case .trips: "Trips"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        case .food: "fork.knife"
        case .trips: "suitcase.rolling"
        case .settings: "gearshape"
        }
    }
}

// MARK: - MusicRoute

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}
