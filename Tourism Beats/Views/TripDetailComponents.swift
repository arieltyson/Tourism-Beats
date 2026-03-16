import SwiftUI

// MARK: - TripSummaryCard

struct TripSummaryCard: View {
    let trip: Trip

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Text("Trip Snapshot")
                    .font(TypographyTokens.sectionHeader)
                    .bold()

                TripSummaryMetricsLayout(trip: self.trip)
            }
        }
    }
}

// MARK: - TripSummaryMetricsLayout

struct TripSummaryMetricsLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.small) {
                TripSummaryMetricsChips(trip: self.trip)
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: SpacingTokens.small,
                verticalSpacing: SpacingTokens.small
            ) {
                GridRow {
                    TripSummaryMetricChip(
                        title: "Days",
                        value: self.trip.dayCount.formatted(.number),
                        tint: AppColors.info,
                        systemImage: "calendar"
                    )

                    TripSummaryMetricChip(
                        title: "Activities",
                        value: self.trip.activityCount.formatted(.number),
                        tint: AppColors.coral,
                        systemImage: "list.bullet"
                    )
                }

                GridRow {
                    TripSummaryMetricChip(
                        title: "Done",
                        value: self.trip.completedActivityCount.formatted(.number),
                        tint: AppColors.safe,
                        systemImage: "checkmark.circle"
                    )
                    .gridCellColumns(2)
                }
            }
        }
    }
}

// MARK: - TripSummaryMetricsChips

struct TripSummaryMetricsChips: View {
    let trip: Trip

    var body: some View {
        Group {
            TripSummaryMetricChip(
                title: "Days",
                value: self.trip.dayCount.formatted(.number),
                tint: AppColors.info,
                systemImage: "calendar"
            )
            TripSummaryMetricChip(
                title: "Activities",
                value: self.trip.activityCount.formatted(.number),
                tint: AppColors.coral,
                systemImage: "list.bullet"
            )
            TripSummaryMetricChip(
                title: "Done",
                value: self.trip.completedActivityCount.formatted(.number),
                tint: AppColors.safe,
                systemImage: "checkmark.circle"
            )
        }
    }
}

// MARK: - TripSummaryMetricChip

struct TripSummaryMetricChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        TripsMetricChip(
            title: self.title,
            value: self.value,
            tint: self.tint,
            systemImage: self.systemImage
        )
    }
}

// MARK: - TripNotesCard

struct TripNotesCard: View {
    let notes: String

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                Label("Planning Notes", systemImage: "note.text")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(.primary)

                Text(self.notes)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - TripItinerarySection

struct TripItinerarySection: View {
    let trip: Trip
    let onAddDay: () -> Void
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            TripItineraryHeader(onAddDay: self.onAddDay)

            ForEach(self.trip.sortedDays) { day in
                TripDayCard(
                    day: day,
                    canDelete: self.trip.sortedDays.count > 1,
                    onAddActivity: {
                        self.onAddActivity(day)
                    },
                    onEditActivity: self.onEditActivity,
                    onCycleActivityStatus: self.onCycleActivityStatus,
                    onDeleteActivity: self.onDeleteActivity,
                    onDeleteDay: {
                        self.onDeleteDay(day)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - TripItineraryHeader

struct TripItineraryHeader: View {
    let onAddDay: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                Spacer(minLength: SpacingTokens.small)

                Button("Add Day", systemImage: "plus") {
                    self.onAddDay()
                }
                .buttonStyle(.bordered)
                .tint(AppColors.coral)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                Button("Add Day", systemImage: "plus") {
                    self.onAddDay()
                }
                .buttonStyle(.bordered)
                .tint(AppColors.coral)
            }
        }
    }
}

// MARK: - TripDayCard

struct TripDayCard: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                TripDayHeader(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onDeleteDay: self.onDeleteDay
                )

                if self.day.sortedActivities.isEmpty {
                    VStack(alignment: .leading, spacing: SpacingTokens.small) {
                        Text("No activities yet")
                            .font(TypographyTokens.cardLabel)
                            .foregroundStyle(.secondary)

                        Button("Add First Activity", systemImage: "plus") {
                            self.onAddActivity()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.coral)
                    }
                } else {
                    VStack(spacing: SpacingTokens.small) {
                        ForEach(self.day.sortedActivities) { activity in
                            TripActivityRow(
                                activity: activity,
                                onEdit: {
                                    self.onEditActivity(activity)
                                },
                                onCycleStatus: {
                                    self.onCycleActivityStatus(activity)
                                },
                                onDelete: {
                                    self.onDeleteActivity(activity)
                                }
                            )
                        }
                    }

                    Button("Add Activity", systemImage: "plus") {
                        self.onAddActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.coral)
                }
            }
        }
    }
}

// MARK: - TripDayHeader

struct TripDayHeader: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                TripDayHeaderTitle(day: self.day)

                Spacer(minLength: SpacingTokens.small)

                TripDayHeaderAccessoryContent(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onDeleteDay: self.onDeleteDay
                )
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                TripDayHeaderTitle(day: self.day)

                TripDayHeaderAccessoryContent(
                    day: self.day,
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onDeleteDay: self.onDeleteDay
                )
            }
        }
    }
}

// MARK: - TripDayHeaderTitle

struct TripDayHeaderTitle: View {
    let day: TripDay

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.day.displayLabel)
                .font(TypographyTokens.sectionHeader)
                .bold()

            if let dateLabel = self.day.dateLabel {
                Text(dateLabel)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - TripDayHeaderAccessoryContent

struct TripDayHeaderAccessoryContent: View {
    let day: TripDay
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                TripDayHeaderCounts(day: self.day)
                TripDayHeaderMenu(
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onDeleteDay: self.onDeleteDay
                )
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripDayHeaderCounts(day: self.day)
                TripDayHeaderMenu(
                    canDelete: self.canDelete,
                    onAddActivity: self.onAddActivity,
                    onDeleteDay: self.onDeleteDay
                )
            }
        }
    }
}

// MARK: - TripDayHeaderCounts

struct TripDayHeaderCounts: View {
    let day: TripDay

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            TripsInlineCount(
                title: "Done",
                value: self.day.completedActivityCount.formatted(.number),
                tint: AppColors.safe
            )
            TripsInlineCount(
                title: "Pending",
                value: self.day.pendingActivityCount.formatted(.number),
                tint: AppColors.info
            )
        }
    }
}

// MARK: - TripDayHeaderMenu

struct TripDayHeaderMenu: View {
    let canDelete: Bool
    let onAddActivity: () -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        if self.canDelete {
            Menu("Day Actions", systemImage: "ellipsis.circle") {
                Button("Add Activity", systemImage: "plus") {
                    self.onAddActivity()
                }

                Button("Delete Day", systemImage: "trash", role: .destructive) {
                    self.onDeleteDay()
                }
            }
            .labelStyle(.iconOnly)
        }
    }
}

// MARK: - TripsInlineCount

struct TripsInlineCount: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(self.value)
                .font(TypographyTokens.footnote.monospacedDigit())
                .bold()
                .foregroundStyle(self.tint)
        }
        .padding(.vertical, SpacingTokens.xxSmall)
        .padding(.horizontal, SpacingTokens.xSmall)
        .background(
            self.tint.opacity(0.10),
            in: .rect(cornerRadius: 14, style: .continuous)
        )
    }
}

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
        }
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(
            AppColors.surfaceSecondary.opacity(0.75),
            in: .rect(cornerRadius: 18, style: .continuous)
        )
    }
}
