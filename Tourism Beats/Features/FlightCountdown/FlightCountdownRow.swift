import SwiftUI

struct FlightCountdownRow: View {
    let flight: CountdownFlight

    var body: some View {
        GlassCard(cornerRadius: SettingsLayoutTokens.rowCornerRadius, contentPadding: SpacingTokens.medium) {
            HStack(spacing: SpacingTokens.small) {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(flight.route)
                        .font(.headline)
                        .foregroundStyle(AppColors.label)
                    Text(flight.flightNumber)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryLabel)
                    Text(flight.departureLabel)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: SpacingTokens.small)
                Image(systemName: "chevron.forward")
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
