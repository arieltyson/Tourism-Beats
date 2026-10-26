import SwiftUI

// MARK: - TripsInlineCount

struct TripsInlineCount: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(self.value)
                .font(TypographyTokens.footnote.monospacedDigit())
                .bold()
                .foregroundStyle(self.tint)
        }
        .padding(.vertical, SpacingTokens.xxSmall)
        .padding(.horizontal, SpacingTokens.xSmall)
        .background(
            self.tint.opacity(0.10),
            in: .rect(cornerRadius: 14, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.title): \(self.value)")
    }
}
