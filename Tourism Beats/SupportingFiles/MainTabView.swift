import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    let onSelectFeedback: (FeedbackCategory) -> Void

    @State private var homePath = NavigationPath()
    @State private var mapPath = NavigationPath()
    @State private var foodPath = NavigationPath()
    @State private var tripsPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView(selection: self.$selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: .home) {
                NavigationStack(path: self.$homePath) {
                    HomeView(
                        onExplore: {
                            self.selectedTab = .map
                        },
                        onCitySelected: { city in
                            self.selectedTab = .map
                            self.mapPath.append(city)
                        }
                    )
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                }
            }

            Tab(AppTab.map.title, systemImage: AppTab.map.systemImage, value: .map) {
                NavigationStack(path: self.$mapPath) {
                    WorldView { city in
                        self.mapPath.append(city)
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
        .onChange(of: self.selectedTab) { old, new in
            if old == new {
                // Re-tapping the active tab pops to root.
                self.popToRoot(for: new)
            } else {
                // Reset the tab we're leaving.
                self.popToRoot(for: old)
            }
        }
    }

    private func popToRoot(for tab: AppTab) {
        switch tab {
        case .home: self.homePath = NavigationPath()
        case .map: self.mapPath = NavigationPath()
        case .food: self.foodPath = NavigationPath()
        case .trips: self.tripsPath = NavigationPath()
        case .settings: self.settingsPath = NavigationPath()
        }
    }
}
