import SwiftUI

/// A search result: what it is, where it is, and its code or offset.
struct FlightPickerRow: View {
    let title: String
    var subtitle: String?
    let detail: String
    var isSelected = false

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text(title)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: SpacingTokens.small)
            Text(detail)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .bold()
                    .accessibilityHidden(true)
            }
        }
        // Inside a button, `.primary` would resolve to the tint colour.
        .foregroundStyle(Color.primary)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
