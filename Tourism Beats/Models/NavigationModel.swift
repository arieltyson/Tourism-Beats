import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, search

    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        }
    }
}

// MARK: - MusicRoute

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}
