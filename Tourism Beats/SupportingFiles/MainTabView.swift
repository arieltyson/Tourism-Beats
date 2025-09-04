import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    var body: some View {
        TabView(selection: self.$selectedTab) {
            // ────────── Home ──────────
            NavigationStack(path: self.$homePath) {
                HomeView()
            }
            .tabItem {
                Image(
                    systemName: (self.selectedTab == .home && self.homePath.isEmpty)
                        ? "house.circle.fill" : "house"
                )
                Text("Home")
            }
            .tag(AppTab.home)

            // ───────── Search ─────────
            NavigationStack(path: self.$searchPath) {
                WorldView { city in
                    self.searchPath.append(city)
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
                    systemName: (self.selectedTab == .search && self.searchPath.isEmpty)
                        ? "magnifyingglass.circle.fill" : "magnifyingglass"
                )
                Text("Search")
            }
            .tag(AppTab.search)
        }
        .tint(.white)
        // Helps icon legibility across bright/dark backgrounds behind the transparent bar.
        .toolbarColorScheme(.dark, for: .tabBar)
        .onChange(of: self.selectedTab) { _, new in
            switch new {
            case .home: self.homePath = NavigationPath()
            case .search: self.searchPath = NavigationPath()
            }
        }
    }
}
