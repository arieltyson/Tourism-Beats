import SwiftUI

struct SettingsSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(TypographyTokens.songTitle)
            .bold()
            .foregroundStyle(AppColors.label)
            .accessibilityAddTraits(.isHeader)
    }
}
