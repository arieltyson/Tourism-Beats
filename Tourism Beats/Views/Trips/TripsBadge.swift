import SwiftUI

// MARK: - TripsBadge

struct TripsBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(TypographyTokens.footnote)
            .foregroundStyle(AppColors.onImagePrimary)
            .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.84)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(self.tint.opacity(0.82), in: Capsule())
    }
}
