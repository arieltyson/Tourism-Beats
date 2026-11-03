import SwiftUI

struct SettingsRowContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconWidth = SettingsLayoutTokens.iconWidth

    let title: String
    let systemImage: String
    let tint: Color
    var accessorySystemImage: String?

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: SpacingTokens.small))
            : AnyLayout(HStackLayout(alignment: .center, spacing: SpacingTokens.small))
        layout {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(title)
                .font(TypographyTokens.cardLabel)
                .bold()
                .foregroundStyle(AppColors.label)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let accessorySystemImage, !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: accessorySystemImage)
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, minHeight: SpacingTokens.minimumTapTarget, alignment: .leading)
        .background(AppColors.surfaceSecondary, in: .rect(cornerRadius: SettingsLayoutTokens.rowCornerRadius))
    }
}
