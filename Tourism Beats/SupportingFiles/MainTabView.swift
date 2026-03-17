import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    let onSelectFeedback: (FeedbackCategory) -> Void

    @ScaledMetric(relativeTo: .body) private var floatingTabItemHeight = 56

    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()
    @State private var foodPath = NavigationPath()
    @State private var tripsPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        self.currentTabContent
            .toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .safeAreaPadding(.bottom, self.tabBarClearance)
            .overlay(alignment: .bottom) {
                TourismFloatingTabBar(selectedTab: self.$selectedTab)
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

    private var tabBarClearance: CGFloat {
        self.floatingTabItemHeight
            + (SpacingTokens.xxSmall * 2)
            + (SpacingTokens.xSmall * 3)
            + SpacingTokens.small
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch self.selectedTab {
        case .home:
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
            }
        case .search:
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
        case .food:
            NavigationStack(path: self.$foodPath) {
                FoodView()
            }
        case .trips:
            NavigationStack(path: self.$tripsPath) {
                TripsView()
            }
        case .settings:
            NavigationStack(path: self.$settingsPath) {
                SettingsView(onSelectFeedback: self.onSelectFeedback)
            }
        }
    }
}
