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
                SettingsToolsSection()

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

            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.large)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationDestination(for: FlightCountdownRoute.self) { _ in
            FlightCountdownView()
        }
    }
}
