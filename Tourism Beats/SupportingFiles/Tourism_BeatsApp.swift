import SwiftUI

@main
struct Tourism_BeatsApp: App {
    init() {
        // UINavigationBar — transparent
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.backgroundEffect = nil
        nav.shadowColor = .clear

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = nav
        navBar.scrollEdgeAppearance = nav
        navBar.compactAppearance = nav
        navBar.tintColor = .white

        // UITabBar — fully transparent w/ SwiftUI supplying any material fallback.
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundColor = .clear
        tab.backgroundEffect = nil
        tab.shadowColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.isTranslucent = true
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .white
    }

    var body: some Scene {
        WindowGroup { MainTabView() }
    }
}
