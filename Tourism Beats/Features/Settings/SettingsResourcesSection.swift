import SwiftUI

// MARK: - SettingsResourcesSection

struct SettingsResourcesSection: View {
    let accessibilityURL: URL?
    let privacyURL: URL?

    var body: some View {
        GlassCard(cornerRadius: SettingsLayoutTokens.sectionCornerRadius) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsSectionTitle(
                    title: "Policies"
                )

                if let accessibilityURL {
                    Link(destination: accessibilityURL) {
                        SettingsRowContent(
                            title: "Accessibility Support",
                            systemImage: "figure.wave.circle",
                            tint: AppColors.info,
                            accessorySystemImage: "arrow.up.right"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let privacyURL {
                    Link(destination: privacyURL) {
                        SettingsRowContent(
                            title: "Privacy Policy",
                            systemImage: "hand.raised.square",
                            tint: AppColors.info,
                            accessorySystemImage: "arrow.up.right"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
