import UIKit

/// Home Screen quick actions available from the app icon.
enum QuickAction: String, CaseIterable, Sendable {
    case searchDestinations = "com.arieljtyson.TourismBeats.quickAction.search"
    case exploreHome = "com.arieljtyson.TourismBeats.quickAction.explore"
    case foodJournal = "com.arieljtyson.TourismBeats.quickAction.food"

    init?(shortcutItem: UIApplicationShortcutItem) {
        self.init(rawValue: shortcutItem.type)
    }

    /// The tab this quick action should navigate to.
    var targetTab: AppTab {
        switch self {
        case .searchDestinations: .search
        case .exploreHome: .home
        case .foodJournal: .food
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
        case .foodJournal:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Food Journal",
                localizedSubtitle: "Your restaurant lists",
                icon: UIApplicationShortcutIcon(systemImageName: "fork.knife.circle"),
                userInfo: nil
            )
        }
    }

    /// Registers all quick actions on the shared application.
    @MainActor
    static func registerAll(in application: UIApplication) {
        application.shortcutItems = allCases.map(\.shortcutItem)
    }
}
