import SwiftUI

// MARK: - BucketListRow

/// One item on the list, checked off with a tap anywhere on the row.
struct BucketListRow: View {
    let item: BucketListItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: self.onToggle) {
            HStack(spacing: SpacingTokens.small) {
                Image(systemName: self.item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(self.item.isCompleted ? AnyShapeStyle(AppColors.gold) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.title)
                        .foregroundStyle(self.item.isCompleted ? .secondary : .primary)

                    if let detail = self.item.placeDetail {
                        Text(detail)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.accessibilityTitle)
        .accessibilityValue(self.item.isCompleted ? "Done" : "Not done")
        .accessibilityHint(self.item.isCompleted ? "Marks it as not done" : "Checks it off")
        .accessibilityAddTraits(self.item.isCompleted ? .isSelected : [])
    }

    /// A place leads with its country's flag.
    private var title: String {
        guard self.item.kind == .place, !self.item.countryFlag.isEmpty else {
            return self.item.title
        }
        return "\(self.item.countryFlag) \(self.item.title)"
    }

    private var accessibilityTitle: String {
        [self.item.title, self.item.placeDetail].compactMap(\.self).joined(separator: ", ")
    }
}
