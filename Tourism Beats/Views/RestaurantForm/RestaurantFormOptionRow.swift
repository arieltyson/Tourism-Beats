import SwiftUI

// MARK: - RestaurantFormOptionRow

/// A choosable row in one of the restaurant form's lists, checked when selected.
struct RestaurantFormOptionRow: View {
    let title: String
    var subtitle: String?
    var flag: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: SpacingTokens.small) {
                if let flag {
                    Text(flag)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.title)
                        .foregroundStyle(Color.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer(minLength: SpacingTokens.small)

                if self.isSelected {
                    Image(systemName: "checkmark")
                        .bold()
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    }
}
