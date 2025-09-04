import SwiftUI

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
                Image(
                    systemName: (selectedTab == .home && homePath.isEmpty)
                        ? "house.circle.fill" : "house"
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
                        ? "magnifyingglass.circle.fill" : "magnifyingglass"
                )
                Text("Search")
            }
            .tag(AppTab.search)
        }
        .tint(.white)
        // Helps icon legibility across bright/dark backgrounds behind the transparent bar.
        .toolbarColorScheme(.dark, for: .tabBar)
        .onChange(of: selectedTab) { _, new in
            switch new {
            case .home: homePath = NavigationPath()
            case .search: searchPath = NavigationPath()
            }
        }
    }
}
