import SwiftUI

// MARK: - TripCountryPickerFieldInlineContent

struct TripCountryPickerFieldInlineContent: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool

    var body: some View {
        HStack(alignment: .center, spacing: SpacingTokens.small) {
            Label("Country", systemImage: "globe")
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)

            Spacer(minLength: SpacingTokens.small)

            HStack(alignment: .center, spacing: SpacingTokens.xSmall) {
                Text(self.countryDisplayLabel)
                    .foregroundStyle(self.hasCountryValue ? .secondary : .tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.down")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
