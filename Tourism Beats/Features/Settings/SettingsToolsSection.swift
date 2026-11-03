import SwiftUI

struct SettingsToolsSection: View {
    var body: some View {
        GlassCard(cornerRadius: SettingsLayoutTokens.sectionCornerRadius) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsSectionTitle(title: "Tools")
                NavigationLink(value: FlightCountdownRoute.countdown) {
                    HStack(spacing: SpacingTokens.small) {
                        Image(systemName: "airplane.departure")
                            .font(.title3)
                            .foregroundStyle(AppColors.info)
                            .frame(width: SettingsLayoutTokens.iconWidth)
                            .accessibilityHidden(true)
                        Text("Flight Countdown")
                            .font(TypographyTokens.cardLabel)
                            .bold()
                            .foregroundStyle(AppColors.label)
                        Spacer(minLength: SpacingTokens.small)
                        Image(systemName: "chevron.forward")
                            .font(.footnote)
                            .foregroundStyle(AppColors.secondaryLabel)
                            .accessibilityHidden(true)
                    }
                    .padding(SpacingTokens.medium)
                    .frame(maxWidth: .infinity, minHeight: SpacingTokens.minimumTapTarget, alignment: .leading)
                    .background(AppColors.surfaceSecondary, in: .rect(cornerRadius: SettingsLayoutTokens.rowCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
