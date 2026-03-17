import UIKit

/// Home Screen quick actions available from the app icon.
enum QuickAction: String, CaseIterable, Sendable {
    case searchDestinations = "com.arieljtyson.TourismBeats.quickAction.search"
    case exploreHome = "com.arieljtyson.TourismBeats.quickAction.explore"
    case foodJournal = "com.arieljtyson.TourismBeats.quickAction.food"
    case trips = "com.arieljtyson.TourismBeats.quickAction.trips"
    case reportBug = "com.arieljtyson.TourismBeats.quickAction.reportBug"
    case suggestFeature = "com.arieljtyson.TourismBeats.quickAction.suggestFeature"

    init?(shortcutItem: UIApplicationShortcutItem) {
        self.init(rawValue: shortcutItem.type)
    }

    /// The tab this quick action should navigate to.
    var targetTab: AppTab {
        switch self {
        case .searchDestinations: .search
        case .exploreHome: .home
        case .foodJournal: .food
        case .trips: .trips
        case .reportBug, .suggestFeature: .settings
        }
    }

    var feedbackCategory: FeedbackCategory? {
        switch self {
        case .reportBug: .bug
        case .suggestFeature: .feature
        default: nil
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
        case .trips:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Trips",
                localizedSubtitle: "Open itineraries",
                icon: UIApplicationShortcutIcon(systemImageName: "suitcase.rolling"),
                userInfo: nil
            )
        case .reportBug:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Report a Bug",
                localizedSubtitle: "Open feedback",
                icon: UIApplicationShortcutIcon(systemImageName: "ladybug"),
                userInfo: nil
            )
        case .suggestFeature:
            UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Suggest a Feature",
                localizedSubtitle: "Share an idea",
                icon: UIApplicationShortcutIcon(systemImageName: "lightbulb"),
                userInfo: nil
            )
        }
    }

    /// iOS surfaces a maximum of four Home Screen quick actions.
    static let displayedActions: [QuickAction] = [
        .searchDestinations,
        .trips,
        .reportBug,
        .suggestFeature
    ]

    /// Registers all quick actions on the shared application.
    @MainActor
    static func registerAll(in application: UIApplication) {
        application.shortcutItems = self.displayedActions.map(\.shortcutItem)
    }
}
