import SwiftUI

// MARK: - TripActivityRow

struct TripActivityRow: View {
    let activity: TripActivity
    let onEdit: () -> Void
    let onCycleStatus: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.small) {
            Button(
                "Update Status",
                systemImage: self.activity.activityStatus.systemImage
            ) {
                self.onCycleStatus()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(self.activity.activityStatus.color)
            .accessibilityInputLabels(["Update Status", "Mark \(self.activity.activityStatus.next.label)"])

            Button {
                self.onEdit()
            } label: {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    HStack(spacing: SpacingTokens.xSmall) {
                        Label(
                            self.activity.type.label,
                            systemImage: self.activity.type.systemImage
                        )
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(self.activity.type.color)

                        if let timeLabel = self.activity.timeLabel {
                            Text(timeLabel)
                                .font(TypographyTokens.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(self.activity.name)
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let location = self.activity.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let notes = self.activity.notes, !notes.isEmpty {
                        Text(notes)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(self.activitySummary)
            .accessibilityHint("Edits this activity")
            .accessibilityInputLabels(["Edit \(self.activity.name)", self.activity.name])

            Menu("Activity Actions", systemImage: "ellipsis.circle") {
                Button("Edit Activity", systemImage: "pencil") {
                    self.onEdit()
                }

                Button(
                    "Mark \(self.activity.activityStatus.next.label)",
                    systemImage: self.activity.activityStatus.next.systemImage
                ) {
                    self.onCycleStatus()
                }

                Button("Delete Activity", systemImage: "trash", role: .destructive) {
                    self.onDelete()
                }
            }
            .labelStyle(.iconOnly)
            .accessibilityInputLabels(["Activity Actions", "More Activity Actions"])
        }
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(
            AppColors.surfaceSecondary.opacity(0.75),
            in: .rect(cornerRadius: 18, style: .continuous)
        )
    }

    private var activitySummary: String {
        [
            self.activity.name,
            self.activity.type.label,
            self.activity.timeLabel,
            self.activity.location,
            self.activity.activityStatus.label
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: ", ")
    }
}
