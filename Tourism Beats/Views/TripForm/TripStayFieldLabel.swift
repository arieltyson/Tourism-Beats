import SwiftUI

// MARK: - TripStayFieldLabel

/// The hotel row's content: marked optional until one is chosen.
struct TripStayFieldLabel: View {
    let stay: TripStay?

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            Label {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.stay?.name ?? String(localized: "Hotel"))
                        .foregroundStyle(.primary)
                    if let address = self.stay?.address {
                        Text(address)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "bed.double")
            }

            if self.stay == nil {
                Spacer(minLength: SpacingTokens.small)
                Text("Optional")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
