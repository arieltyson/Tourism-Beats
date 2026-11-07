import SwiftUI

// MARK: - BucketListConfirmationCard

/// A card in the middle of the screen saying a place was added or removed.
///
/// A thick material keeps the message legible over any page beneath it.
struct BucketListConfirmationCard: View {
    let confirmation: BucketListConfirmation

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: SpacingTokens.small) {
            Image(systemName: self.confirmation.systemImage)
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(self.confirmation.wasAdded ? AppColors.gold : AppColors.secondaryLabel)

            Text(self.confirmation.message)
                .font(TypographyTokens.sectionHeader)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.large)
        .background(.thickMaterial, in: .rect(cornerRadius: SpacingTokens.large))
        .overlay {
            RoundedRectangle(cornerRadius: SpacingTokens.large)
                .strokeBorder(AppColors.glassBorder(for: self.scheme))
        }
        .shadow(color: AppColors.glassShadow(for: self.scheme), radius: SpacingTokens.medium, y: SpacingTokens.xSmall)
        .padding(SpacingTokens.xxLarge)
        // VoiceOver hears it as an announcement instead.
        .accessibilityHidden(true)
    }
}
