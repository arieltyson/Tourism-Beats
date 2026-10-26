import SwiftUI

// MARK: - TripsMetricChip

struct TripsMetricChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Label(self.title, systemImage: self.systemImage)
                .font(TypographyTokens.footnote)
                .foregroundStyle(self.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(self.value)
                .font(TypographyTokens.cardLabel.monospacedDigit())
                .bold()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(self.tint.opacity(0.12), in: .rect(cornerRadius: 18, style: .continuous))
    }
}
