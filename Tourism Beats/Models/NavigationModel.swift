import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, search
}

// MARK: - MusicRoute

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}
