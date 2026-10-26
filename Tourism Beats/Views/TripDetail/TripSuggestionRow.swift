import SwiftUI

// MARK: - TripSuggestionRow

struct TripSuggestionRow: View {
    let suggestion: TripActivitySuggestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            self.onToggle()
        } label: {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(self.isSelected ? AppColors.coral : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    HStack(spacing: SpacingTokens.xSmall) {
                        Label(
                            self.suggestion.type.label,
                            systemImage: self.suggestion.type.systemImage
                        )
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(self.suggestion.type.color)

                        Text("\(self.suggestion.slot.label) · \(self.timeLabel)")
                            .font(TypographyTokens.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Text(self.suggestion.name)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let location = self.suggestion.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let notes = self.suggestion.notes {
                        Text(notes)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
        .accessibilityHint(self.isSelected ? "Removes it from the plan" : "Adds it to the plan")
    }

    private var timeLabel: String {
        let time = Calendar.current.date(
            bySettingHour: self.suggestion.slot.hour,
            minute: self.suggestion.slot.minute,
            second: 0,
            of: .now
        ) ?? .now
        return time.formatted(date: .omitted, time: .shortened)
    }
}
