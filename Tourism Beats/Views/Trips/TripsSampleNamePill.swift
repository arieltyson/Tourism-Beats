import SwiftUI

// MARK: - TripsSampleNamePill

struct TripsSampleNamePill: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(TypographyTokens.footnote)
            .foregroundStyle(.secondary)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(AppColors.surfaceSecondary, in: Capsule())
    }
}
