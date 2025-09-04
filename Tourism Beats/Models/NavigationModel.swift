import SwiftUI

// MARK: - App Tab Enum

enum AppTab: Hashable {
    case home, search
}

// MARK: - Music Route Model

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}
