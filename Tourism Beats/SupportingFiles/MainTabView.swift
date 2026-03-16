import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    var body: some View {
        TabView(selection: self.$selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack(path: self.$homePath) {
                    HomeView()
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search) {
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
            }
        }
        .tint(.white)
        .toolbarColorScheme(.dark, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onChange(of: self.selectedTab) { _, new in
            switch new {
            case .home: self.homePath = NavigationPath()
            case .search: self.searchPath = NavigationPath()
            }
        }
    }
}
