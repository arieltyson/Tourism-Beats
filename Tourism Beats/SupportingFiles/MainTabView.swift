import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    let onSelectFeedback: (FeedbackCategory) -> Void

    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()
    @State private var foodPath = NavigationPath()
    @State private var tripsPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView(selection: self.$selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: .home) {
                NavigationStack(path: self.$homePath) {
                    HomeView(
                        onExplore: {
                            self.selectedTab = .search
                        },
                        onCitySelected: { city in
                            self.selectedTab = .search
                            self.searchPath.append(city)
                        }
                    )
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }

            Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: .search) {
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
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }

            Tab(AppTab.food.title, systemImage: AppTab.food.systemImage, value: .food) {
                NavigationStack(path: self.$foodPath) {
                    FoodView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }

            Tab(AppTab.trips.title, systemImage: AppTab.trips.systemImage, value: .trips) {
                NavigationStack(path: self.$tripsPath) {
                    TripsView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: .settings) {
                NavigationStack(path: self.$settingsPath) {
                    SettingsView(onSelectFeedback: self.onSelectFeedback)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }
        }
        .onChange(of: self.selectedTab) { old, _ in
            // Reset the tab we're *leaving*, not the one we're arriving at.
            // This preserves any path appended before the switch (e.g. featured city).
            switch old {
            case .home: self.homePath = NavigationPath()
            case .search: self.searchPath = NavigationPath()
            case .food: self.foodPath = NavigationPath()
            case .trips: self.tripsPath = NavigationPath()
            case .settings: self.settingsPath = NavigationPath()
            }
        }
    }
}
