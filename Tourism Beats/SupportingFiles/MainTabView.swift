import SwiftUI

enum AppTab: Hashable {
    case home, search
}

/// Wrapper so we can push MusicView on the same navigation stack
struct MusicRoute: Hashable {
    let city: CityModel
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    init() {
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = .white
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // ────────── Home ──────────
            NavigationStack(path: $homePath) {
                HomeView()
            }
            .tabItem {
                Image(
                    systemName: (selectedTab == .home && homePath.isEmpty)
                        ? "house.circle.fill"
                        : "house"
                )
                Text("Home")
            }
            .tag(AppTab.home)

            // ───────── Search ─────────
            NavigationStack(path: $searchPath) {
                WorldView { city in
                    searchPath.append(city)
                }
                .navigationDestination(for: CityModel.self) { city in
                    CityContainerView(city: city)
                }
                .navigationDestination(for: MusicRoute.self) { route in
                    MusicView(
                        city: route.city,
                        fallbackView: FallbackMusicView()
                    )
                }
            }
            .tabItem {
                Image(
                    systemName: (selectedTab == .search && searchPath.isEmpty)
                        ? "magnifyingglass.circle.fill"
                        : "magnifyingglass"
                )
                Text("Search")
            }
            .tag(AppTab.search)
        }
        .tint(.white)
        // whenever the user switches tabs, wipe out that stack
        .onChange(of: selectedTab) { new in
            switch new {
            case .home:
                homePath = NavigationPath()
            case .search:
                searchPath = NavigationPath()
            }
        }
    }
}
