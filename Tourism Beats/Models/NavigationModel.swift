import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, search, food

    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .food: "Food"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        case .food: "fork.knife"
        }
    }
}

// MARK: - MusicRoute

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}
