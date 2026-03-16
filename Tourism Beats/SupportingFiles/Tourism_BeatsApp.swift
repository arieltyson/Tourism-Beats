import SwiftUI
import UIKit

// MARK: - Tourism_BeatsApp

@main
struct Tourism_BeatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var selectedTab: AppTab = .home
    @State private var launchPhase: LaunchPhase = .branded

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Content layer — visible once launch animation completes.
                if self.launchPhase == .ready {
                    MainTabView(selectedTab: self.$selectedTab)
                        .transition(.opacity)
                }

                // Branded overlay — dismisses itself after animation.
                if self.launchPhase == .branded {
                    LaunchAnimationView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            self.launchPhase = .ready
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: self.launchPhase)
            .task {
                self.appDelegate.onQuickAction = { action in
                    self.selectedTab = action.targetTab
                }
            }
        }
    }
}

// MARK: - LaunchPhase

private enum LaunchPhase: Equatable {
    /// Branded animation is playing.
    case branded
    /// Full content is visible.
    case ready
}

// MARK: - AppDelegate

/// Handles quick action routing and system-level lifecycle events.
final class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {
    /// Callback for routing quick actions into the SwiftUI layer.
    var onQuickAction: ((QuickAction) -> Void)?

    /// Quick action captured before the SwiftUI layer has connected.
    private var deferredAction: UIApplicationShortcutItem?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        QuickAction.registerAll(in: application)
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            self.deferredAction = shortcutItem
        }
        return UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(self.routeQuickAction(shortcutItem))
    }

    /// Flushes any deferred quick action once the SwiftUI layer is ready.
    func flushDeferredActionIfNeeded() {
        guard let action = self.deferredAction else { return }
        self.deferredAction = nil
        self.routeQuickAction(action)
    }

    @discardableResult
    private func routeQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(shortcutItem: shortcutItem) else {
            return false
        }

        if let onQuickAction {
            onQuickAction(action)
        } else {
            self.deferredAction = shortcutItem
        }
        return true
    }
}
