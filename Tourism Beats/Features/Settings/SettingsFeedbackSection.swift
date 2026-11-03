import SwiftUI

// MARK: - SettingsFeedbackSection

struct SettingsFeedbackSection: View {
    let reviewURL: URL
    let onReportBug: () -> Void
    let onSuggestFeature: () -> Void

    var body: some View {
        GlassCard(cornerRadius: SettingsLayoutTokens.sectionCornerRadius) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsSectionTitle(title: "Support")

                SettingsLinkActionRow(
                    title: "Rate Tourism Beats",
                    systemImage: "star.fill",
                    tint: AppColors.gold,
                    destination: self.reviewURL,
                    accessorySystemImage: "arrow.up.right",
                    accessibilityHint: "Opens the App Store review page for Tourism Beats."
                )

                SettingsActionRow(
                    title: FeedbackCategory.bug.title,
                    systemImage: FeedbackCategory.bug.systemImage,
                    tint: AppColors.coral,
                    accessibilityHint: "Opens the bug report feedback flow.",
                    accessibilityInputLabels: FeedbackCategory.bug.accessibilityInputLabels,
                    action: self.onReportBug
                )

                SettingsActionRow(
                    title: FeedbackCategory.feature.title,
                    systemImage: FeedbackCategory.feature.systemImage,
                    tint: AppColors.info,
                    accessibilityHint: "Opens the feature request feedback flow.",
                    accessibilityInputLabels: FeedbackCategory.feature.accessibilityInputLabels,
                    action: self.onSuggestFeature
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
