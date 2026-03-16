import Foundation
import OSLog
import SwiftData
import SwiftUI

// MARK: - AppSceneRootView

struct AppSceneRootView: View {
    let appDelegate: AppDelegate

    @Binding var selectedTab: AppTab

    @Environment(\.modelContext) private var modelContext

    @State private var launchPhase: LaunchPhase = .branded
    @State private var hasPerformedStartupTasks = false

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "AppSceneRootView"
    )

    var body: some View {
        ZStack {
            if self.launchPhase == .ready {
                MainTabView(selectedTab: self.$selectedTab)
                    .transition(.opacity)
            }

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
            self.appDelegate.flushDeferredActionIfNeeded()
        }
        .task {
            guard !self.hasPerformedStartupTasks else { return }
            self.hasPerformedStartupTasks = true

            do {
                try RestaurantMealPhotoOwnershipRepairService().repairIfNeeded(
                    in: self.modelContext
                )
            } catch {
                self.logger.error(
                    "Meal photo ownership repair failed: \(error.localizedDescription, privacy: .public)"
                )
            }

            do {
                try TripSeedService.seedIfNeeded(in: self.modelContext)
            } catch {
                self.logger.error(
                    "Trip sample seeding failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }
}

// MARK: - LaunchPhase

private enum LaunchPhase: Equatable {
    case branded
    case ready
}
