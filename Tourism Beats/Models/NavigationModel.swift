import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, map, food, trips, settings

    var title: String {
        switch self {
        case .home: "Home"
        case .map: "Map"
        case .food: "Food"
        case .trips: "Trips"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .map: "map"
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
