import UIKit

/// Home Screen quick actions available from the app icon.
enum QuickAction: String, CaseIterable, Sendable {
    case searchDestinations = "com.arieljtyson.TourismBeats.quickAction.search"
    case exploreHome = "com.arieljtyson.TourismBeats.quickAction.explore"

    init?(shortcutItem: UIApplicationShortcutItem) {
        self.init(rawValue: shortcutItem.type)
    }

    /// The tab this quick action should navigate to.
    var targetTab: AppTab {
        switch self {
        case .searchDestinations: .search
        case .exploreHome: .home
        }
    }

    var shortcutItem: UIApplicationShortcutItem {
        switch self {
        case .searchDestinations:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Search Destinations",
                localizedSubtitle: "Find cities to explore",
                icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass.circle"),
                userInfo: nil
            )
        case .exploreHome:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Explore",
                localizedSubtitle: "An immersive experience",
                icon: UIApplicationShortcutIcon(systemImageName: "globe.europe.africa"),
                userInfo: nil
            )
        }
    }

    /// Registers all quick actions on the shared application.
    static func registerAll(in application: UIApplication = .shared) {
        application.shortcutItems = allCases.map(\.shortcutItem)
    }
}
