import SwiftUI

// MARK: - BucketListCityPickerRow

/// A city to choose, with a checkmark on the one chosen.
struct BucketListCityPickerRow: View {
    let title: String
    let detail: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.title)
                        .foregroundStyle(.primary)

                    if let detail {
                        Text(detail)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if self.isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    }
}
