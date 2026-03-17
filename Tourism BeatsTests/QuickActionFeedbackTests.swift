import Testing
@testable import Tourism_Beats

struct QuickActionFeedbackTests {
    @Test func feedbackQuickActionsRouteToSettingsAndExpectedCategories() {
        #expect(QuickAction.reportBug.targetTab == .settings)
        #expect(QuickAction.suggestFeature.targetTab == .settings)
        #expect(QuickAction.reportBug.feedbackCategory == .bug)
        #expect(QuickAction.suggestFeature.feedbackCategory == .feature)
    }

    @Test func displayedQuickActionsRespectHomeScreenLimit() {
        #expect(QuickAction.displayedActions.count == 4)
        #expect(QuickAction.displayedActions.contains(.reportBug))
        #expect(QuickAction.displayedActions.contains(.suggestFeature))
    }
}
