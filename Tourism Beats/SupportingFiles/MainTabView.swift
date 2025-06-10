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

    var body: some View {
        TabView(selection: $selectedTab) {
            // ────────── Home ──────────
            NavigationStack(path: $homePath) {
                HomeView()
            }
            .tabItem {
                Label(
                    "Home",
                    systemImage: (selectedTab == .home && homePath.isEmpty)
                        ? "house.circle.fill"
                        : "house"
                )
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
                Label(
                    "Search",
                    systemImage: (selectedTab == .search && searchPath.isEmpty)
                        ? "magnifyingglass.circle.fill"
                        : "magnifyingglass"
                )
            }
            .tag(AppTab.search)
        }
        .tint(.white)
        // whenever the user switches tabs, wipe out that stack
        .onChange(of: selectedTab) {
            switch selectedTab {
            case .home:
                searchPath = NavigationPath()
            case .search:
                homePath = NavigationPath()
            }
        }
    }
}
