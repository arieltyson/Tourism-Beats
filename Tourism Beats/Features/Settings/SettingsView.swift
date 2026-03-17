import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    let onSelectFeedback: (FeedbackCategory) -> Void

    private let accessibilityURL = URL(
        string: "https://arieltyson.github.io/tourism-beats-accessibility/"
    )
    private let privacyURL = URL(
        string: "https://arieltyson.github.io/tourism-beats-privacy/"
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                SettingsFeedbackSection(
                    onReportBug: {
                        self.onSelectFeedback(.bug)
                    },
                    onSuggestFeature: {
                        self.onSelectFeedback(.feature)
                    }
                )

                SettingsResourcesSection(
                    accessibilityURL: self.accessibilityURL,
                    privacyURL: self.privacyURL
                )

                SettingsVersionFooter()
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.large)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}

// MARK: - SettingsFeedbackSection

private struct SettingsFeedbackSection: View {
    let onReportBug: () -> Void
    let onSuggestFeature: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text("Feedback")
                .font(TypographyTokens.heroTitle)
                .bold()
                .foregroundStyle(AppColors.label)
                .accessibilityAddTraits(.isHeader)

            Text(
                "Send issues and ideas through a lighter feedback flow that opens your mail app with the right context already attached."
            )
            .font(TypographyTokens.body)
            .foregroundStyle(AppColors.secondaryLabel)

            GlassCard(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    SettingsSectionTitle(
                        title: "Share with us",
                        subtitle: "Choose the path that best matches what you want to send."
                    )

                    SettingsActionButton(
                        category: .bug,
                        action: self.onReportBug
                    )

                    SettingsActionButton(
                        category: .feature,
                        action: self.onSuggestFeature
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - SettingsResourcesSection

private struct SettingsResourcesSection: View {
    let accessibilityURL: URL?
    let privacyURL: URL?

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsSectionTitle(
                    title: "Support and policies",
                    subtitle: "Open the public accessibility support page or privacy policy any time."
                )

                if let accessibilityURL {
                    Link(destination: accessibilityURL) {
                        SettingsResourceRow(
                            title: "Accessibility Support",
                            subtitle: "Feature support and accommodation details",
                            systemImage: "figure.wave.circle"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let privacyURL {
                    Link(destination: privacyURL) {
                        SettingsResourceRow(
                            title: "Privacy Policy",
                            subtitle: "How Tourism Beats handles your data",
                            systemImage: "hand.raised.square"
                        )
                    }
                    .buttonStyle(.plain)
                }

                SettingsContactRow(email: FeedbackMailComposer.supportEmail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SettingsSectionTitle

private struct SettingsSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.title)
                .font(TypographyTokens.songTitle)
                .bold()
                .foregroundStyle(AppColors.label)

            Text(self.subtitle)
                .font(TypographyTokens.body)
                .foregroundStyle(AppColors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - SettingsActionButton

private struct SettingsActionButton: View {
    let category: FeedbackCategory
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                Image(systemName: self.category.systemImage)
                    .font(.title3)
                    .foregroundStyle(self.iconTint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.category.title)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text(self.category.summary)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: SpacingTokens.small)

                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .padding(SpacingTokens.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColors.surfaceSecondary,
                in: .rect(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityInputLabels(self.category.accessibilityInputLabels)
    }

    private var iconTint: Color {
        switch self.category {
        case .bug: AppColors.coral
        case .feature: AppColors.info
        }
    }
}

// MARK: - SettingsResourceRow

private struct SettingsResourceRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: SpacingTokens.small) {
            Image(systemName: self.systemImage)
                .font(.title3)
                .foregroundStyle(AppColors.info)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text(self.title)
                    .font(TypographyTokens.cardLabel)
                    .bold()
                    .foregroundStyle(AppColors.label)

                Text(self.subtitle)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: SpacingTokens.small)

            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .foregroundStyle(AppColors.secondaryLabel)
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.surfaceSecondary,
            in: .rect(cornerRadius: 22, style: .continuous)
        )
    }
}

// MARK: - SettingsContactRow

private struct SettingsContactRow: View {
    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text("Support Email")
                .font(TypographyTokens.cardLabel)
                .bold()
                .foregroundStyle(AppColors.label)

            Text(self.email)
                .font(TypographyTokens.body.monospaced())
                .foregroundStyle(AppColors.secondaryLabel)
                .textSelection(.enabled)
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.surfaceSecondary,
            in: .rect(cornerRadius: 22, style: .continuous)
        )
    }
}

// MARK: - SettingsVersionFooter

private struct SettingsVersionFooter: View {
    private let shortVersion =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as? String ?? "Unknown"
    private let buildNumber =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        as? String ?? "Unknown"

    var body: some View {
        Text("Tourism Beats \(self.shortVersion) (\(self.buildNumber))")
            .font(TypographyTokens.footnote)
            .foregroundStyle(AppColors.secondaryLabel)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, SpacingTokens.large)
    }
}
