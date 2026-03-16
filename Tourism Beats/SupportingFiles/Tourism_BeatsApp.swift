import SwiftUI

@main
struct Tourism_BeatsApp: App {
    init() {
        // UINavigationBar — transparent so SwiftUI controls appearance.
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
    }

    var body: some Scene {
        WindowGroup { MainTabView() }
    }
}
