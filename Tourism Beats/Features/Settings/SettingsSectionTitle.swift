import SwiftUI

// MARK: - SettingsSectionTitle

struct SettingsSectionTitle: View {
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
                .accessibilityAddTraits(.isHeader)

            if let subtitle {
                Text(subtitle)
                    .font(TypographyTokens.body)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

