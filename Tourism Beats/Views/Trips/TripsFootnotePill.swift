import SwiftUI

// MARK: - TripsFootnotePill

struct TripsFootnotePill: View {
    let title: String
    let systemImage: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(TypographyTokens.footnote)
            .foregroundStyle(AppColors.onImagePrimary)
            .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.84)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(AppColors.imageBadgeFill, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppColors.imageBadgeBorder, lineWidth: 1)
            }
    }
}
