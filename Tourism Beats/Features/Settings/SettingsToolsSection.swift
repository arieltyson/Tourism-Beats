import SwiftUI

struct SettingsToolsSection: View {
    var body: some View {
        GlassCard(cornerRadius: SettingsLayoutTokens.sectionCornerRadius) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                SettingsSectionTitle(title: "Tools")
                NavigationLink(value: FlightCountdownRoute.countdown) {
                    SettingsRowContent(
                        title: "Flight Countdown",
                        systemImage: "airplane.departure",
                        tint: AppColors.info,
                        accessorySystemImage: "chevron.forward"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
