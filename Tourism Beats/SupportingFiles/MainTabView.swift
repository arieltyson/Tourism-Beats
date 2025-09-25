import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                baseView
                    // Let the system bar be fully transparent.
                    .toolbarBackground(.clear, for: .tabBar)
                    .toolbarBackgroundVisibility(.visible, for: .tabBar)
                    // Draw the glass BEHIND the TabView so it can’t duplicate up top.
                    .background(alignment: .bottom) {
                        LiquidTabBarBackground()
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.995))
                            )
                            .accessibilityHidden(true)
                    }
            } else {
                baseView
                    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                    .toolbarBackgroundVisibility(.visible, for: .tabBar)
            }
        }
    }

    private var baseView: some View {
        TabView(selection: $selectedTab) {
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
        .toolbarColorScheme(.dark, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onChange(of: selectedTab) { _, new in
            switch new {
            case .home: homePath = NavigationPath()
            case .search: searchPath = NavigationPath()
            }
        }
    }
}
