import SwiftUI

// MARK: - TripStayRecommendationRow

/// A recommended hotel, picked or not, like the plan's suggestions.
struct TripStayRecommendationRow: View {
    let stay: TripStay
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: self.onToggle) {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(self.isSelected ? AppColors.coral : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Label(ActivityType.accommodation.label, systemImage: ActivityType.accommodation.systemImage)
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ActivityType.accommodation.color)

                    Text(self.stay.name)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let address = self.stay.address {
                        Label(address, systemImage: "mappin.and.ellipse")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
        .accessibilityHint(self.isSelected ? "Leaves the trip without a hotel" : "Makes it the trip's hotel")
    }
}
