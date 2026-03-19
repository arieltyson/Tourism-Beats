import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    let onSelectFeedback: (FeedbackCategory) -> Void

    private let appStoreReviewURL = TourismBeatsAppStore.reviewURL
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
                    reviewURL: self.appStoreReviewURL,
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
    let reviewURL: URL
    let onReportBug: () -> Void
    let onSuggestFeature: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsLinkActionRow(
                    title: "Rate Tourism Beats",
                    subtitle: "Open the App Store review page for Tourism Beats.",
                    systemImage: "star.fill",
                    tint: AppColors.gold,
                    destination: self.reviewURL,
                    accessorySystemImage: "arrow.up.right",
                    accessibilityHint: "Opens the App Store review page for Tourism Beats."
                )

                SettingsActionRow(
                    title: FeedbackCategory.bug.title,
                    subtitle: FeedbackCategory.bug.summary,
                    systemImage: FeedbackCategory.bug.systemImage,
                    tint: AppColors.coral,
                    accessorySystemImage: "arrow.up.right",
                    accessibilityHint: "Opens the bug report feedback flow.",
                    accessibilityInputLabels: FeedbackCategory.bug.accessibilityInputLabels,
                    action: self.onReportBug
                )

                SettingsActionRow(
                    title: FeedbackCategory.feature.title,
                    subtitle: FeedbackCategory.feature.summary,
                    systemImage: FeedbackCategory.feature.systemImage,
                    tint: AppColors.info,
                    accessorySystemImage: "arrow.up.right",
                    accessibilityHint: "Opens the feature request feedback flow.",
                    accessibilityInputLabels: FeedbackCategory.feature.accessibilityInputLabels,
                    action: self.onSuggestFeature
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    title: "Policies"
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SettingsSectionTitle

private struct SettingsSectionTitle: View {
    let title: String
    var subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.title)
                .font(TypographyTokens.songTitle)
                .bold()
                .foregroundStyle(AppColors.label)

            if let subtitle {
                Text(subtitle)
                    .font(TypographyTokens.body)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - SettingsActionRow

private struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var accessorySystemImage: String?
    var accessibilityHint: String?
    var accessibilityInputLabels: [String] = []
    let action: () -> Void

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        accessorySystemImage: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityInputLabels: [String] = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.accessorySystemImage = accessorySystemImage
        self.accessibilityHint = accessibilityHint
        self.accessibilityInputLabels = accessibilityInputLabels
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
            SettingsActionRowContent(
                title: self.title,
                subtitle: self.subtitle,
                systemImage: self.systemImage,
                tint: self.tint,
                accessorySystemImage: self.accessorySystemImage
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(self.accessibilityHint ?? "")
        .accessibilityInputLabels(self.accessibilityInputLabels)
    }
}

// MARK: - SettingsLinkActionRow

private struct SettingsLinkActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let destination: URL
    var accessorySystemImage: String?
    var accessibilityHint: String?
    var accessibilityInputLabels: [String] = []

    var body: some View {
        Link(destination: self.destination) {
            SettingsActionRowContent(
                title: self.title,
                subtitle: self.subtitle,
                systemImage: self.systemImage,
                tint: self.tint,
                accessorySystemImage: self.accessorySystemImage
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(self.accessibilityHint ?? "")
        .accessibilityInputLabels(self.accessibilityInputLabels)
    }
}

// MARK: - SettingsActionRowContent

private struct SettingsActionRowContent: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var accessorySystemImage: String?

    var body: some View {
        HStack(alignment: .center, spacing: SpacingTokens.small) {
            Image(systemName: self.systemImage)
                .font(.title3)
                .foregroundStyle(self.tint)
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

            if let accessorySystemImage {
                Image(systemName: accessorySystemImage)
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.surfaceSecondary,
            in: .rect(cornerRadius: 22, style: .continuous)
        )
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
