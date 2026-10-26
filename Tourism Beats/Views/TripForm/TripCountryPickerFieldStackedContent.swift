import SwiftUI

// MARK: - TripCountryPickerFieldStackedContent

struct TripCountryPickerFieldStackedContent: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Label("Country", systemImage: "globe")
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            HStack(alignment: .center, spacing: SpacingTokens.xSmall) {
                Text(self.countryDisplayLabel)
                    .foregroundStyle(self.hasCountryValue ? .secondary : .tertiary)
                    .lineLimit(2)

                Spacer(minLength: SpacingTokens.small)

                Image(systemName: "chevron.down")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
