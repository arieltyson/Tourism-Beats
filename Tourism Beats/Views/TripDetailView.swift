import SwiftData
import SwiftUI

// MARK: - TripDetailView

struct TripDetailView: View {
    @Bindable var trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = TripsViewModel()
    @State private var dayForNewActivity: TripDay?
    @State private var activityToEdit: TripActivity?
    @State private var dayPendingDeletion: TripDay?
    @State private var isEditTripPresented: Bool = false
    @State private var isTripDeleteConfirmationPresented: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                TripHeroCard(
                    trip: self.trip,
                    cityModel: self.viewModel.cityModel(for: self.trip),
                    countryFlag: self.viewModel.countryFlag(for: self.trip)
                )

                TripSummaryCard(trip: self.trip)

                if let notes = self.trip.notesSummary {
                    TripNotesCard(notes: notes)
                }

                TripItinerarySection(
                    trip: self.trip,
                    onAddDay: self.addDay,
                    onAddActivity: { day in
                        self.dayForNewActivity = day
                    },
                    onEditActivity: { activity in
                        self.activityToEdit = activity
                    },
                    onCycleActivityStatus: self.cycleActivityStatus,
                    onDeleteActivity: self.deleteActivity,
                    onDeleteDay: { day in
                        self.dayPendingDeletion = day
                    }
                )
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.small)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle(self.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add Day", systemImage: "plus") {
                    self.addDay()
                }
                .labelStyle(.iconOnly)

                Menu {
                    Button("Edit Trip", systemImage: "pencil") {
                        self.isEditTripPresented = true
                    }

                    Button("Delete Trip", systemImage: "trash", role: .destructive) {
                        self.isTripDeleteConfirmationPresented = true
                    }
                } label: {
                    Label("Trip Actions", systemImage: "ellipsis.circle")
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Trip actions")
            }
        }
        .sheet(isPresented: self.$isEditTripPresented) {
            AddEditTripView(trip: self.trip)
        }
        .sheet(item: self.$dayForNewActivity) { day in
            AddEditActivityView(day: day)
        }
        .sheet(item: self.$activityToEdit) { activity in
            if let day = activity.day {
                AddEditActivityView(day: day, activity: activity)
            }
        }
        .confirmationDialog(
            "Delete Trip",
            isPresented: self.$isTripDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) {
                self.confirmDeleteTrip()
            }

            Button("Cancel", role: .cancel) {
                self.isTripDeleteConfirmationPresented = false
            }
        } message: {
            Text("Deleting this trip also removes its days and activities.")
        }
        .confirmationDialog(
            "Delete Day",
            isPresented: self.dayDeleteDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Day", role: .destructive) {
                self.confirmDeleteDay()
            }

            Button("Cancel", role: .cancel) {
                self.dayPendingDeletion = nil
            }
        } message: {
            Text("Deleting a day also removes every activity planned for it.")
        }
        .alert(
            "Couldn't Complete Request",
            isPresented: self.errorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.errorMessage ?? "Please try again.")
        }
    }

    private var dayDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { self.dayPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    self.dayPendingDeletion = nil
                }
            }
        )
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    self.errorMessage = nil
                }
            }
        )
    }

    private func addDay() {
        self.modelContext.insert(
            TripDay(
                dayNumber: self.trip.nextDayNumber,
                date: self.trip.nextDayDate,
                trip: self.trip
            )
        )
        self.persistChanges()
    }

    private func confirmDeleteDay() {
        guard let dayPendingDeletion else { return }
        self.modelContext.delete(dayPendingDeletion)
        self.renumberDays()
        self.persistChanges()
        self.dayPendingDeletion = nil
    }

    private func confirmDeleteTrip() {
        self.isTripDeleteConfirmationPresented = false

        do {
            self.modelContext.delete(self.trip)

            if self.modelContext.hasChanges {
                try self.modelContext.save()
            }

            self.dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func cycleActivityStatus(_ activity: TripActivity) {
        activity.activityStatus = activity.activityStatus.next
        self.persistChanges()
    }

    private func deleteActivity(_ activity: TripActivity) {
        self.modelContext.delete(activity)
        self.persistChanges()
    }

    private func renumberDays() {
        let sortedDays = self.trip.sortedDays
        for (index, day) in sortedDays.enumerated() {
            day.dayNumber = index + 1

            if let tripStartDate = self.trip.startDate {
                day.date = Calendar.current.date(
                    byAdding: .day,
                    value: index,
                    to: tripStartDate
                )
            }
        }
    }

    private func persistChanges() {
        do {
            if self.modelContext.hasChanges {
                try self.modelContext.save()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - TripHeroCard

private struct TripHeroCard: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var cardHeight = 280.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TripHeroBackground(cityModel: self.cityModel)

            LinearGradient(
                colors: [
                    .black.opacity(0.12),
                    .black.opacity(0.28),
                    .black.opacity(0.84)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                HStack(spacing: SpacingTokens.xSmall) {
                    TripsBadge(
                        title: self.trip.status.label,
                        systemImage: self.trip.status.systemImage,
                        tint: self.trip.status.color
                    )

                    if self.trip.isSample {
                        TripsBadge(
                            title: "Sample itinerary",
                            systemImage: "sparkles",
                            tint: AppColors.gold
                        )
                    }
                }

                Spacer(minLength: SpacingTokens.large)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.trip.name)
                        .font(TypographyTokens.heroTitle)
                        .bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("\(self.countryFlag) \(self.trip.displayLocation)")
                        .font(TypographyTokens.songTitle)
                        .foregroundStyle(.white.opacity(0.94))

                    if let dateRangeLabel = self.trip.dateRangeLabel {
                        Label(dateRangeLabel, systemImage: "calendar")
                            .font(TypographyTokens.body)
                            .foregroundStyle(.white.opacity(0.84))
                    }
                }

                HStack(spacing: SpacingTokens.small) {
                    TripsFootnotePill(
                        title: self.trip.scheduleSummaryLabel,
                        systemImage: "list.bullet.rectangle.portrait"
                    )

                    if let progressLabel = self.trip.progressLabel {
                        TripsFootnotePill(
                            title: progressLabel,
                            systemImage: "checkmark.circle"
                        )
                    }
                }
            }
            .padding(SpacingTokens.large)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight)
        .clipShape(.rect(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 18,
            y: 10
        )
    }
}

// MARK: - TripHeroBackground

private struct TripHeroBackground: View {
    let cityModel: CityModel?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            if let cityModel {
                CachedCityImage(url: cityModel.imageURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        AppColors.info.opacity(0.94),
                        AppColors.violet.opacity(0.88),
                        AppColors.magenta.opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(.white.opacity(0.22))
                }
            }
        }
    }
}

// MARK: - TripSummaryCard

private struct TripSummaryCard: View {
    let trip: Trip

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Text("Trip Snapshot")
                    .font(TypographyTokens.sectionHeader)
                    .bold()

                HStack(spacing: SpacingTokens.small) {
                    TripsMetricChip(
                        title: "Days",
                        value: self.trip.dayCount.formatted(.number),
                        tint: AppColors.info,
                        systemImage: "calendar"
                    )
                    TripsMetricChip(
                        title: "Activities",
                        value: self.trip.activityCount.formatted(.number),
                        tint: AppColors.coral,
                        systemImage: "list.bullet"
                    )
                    TripsMetricChip(
                        title: "Done",
                        value: self.trip.completedActivityCount.formatted(.number),
                        tint: AppColors.safe,
                        systemImage: "checkmark.circle"
                    )
                }
            }
        }
    }
}

// MARK: - TripNotesCard

private struct TripNotesCard: View {
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

private struct TripItinerarySection: View {
    let trip: Trip
    let onAddDay: () -> Void
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            HStack {
                Text("Itinerary")
                    .font(TypographyTokens.songTitle)
                    .bold()

                Spacer()

                Button("Add Day", systemImage: "plus") {
                    self.onAddDay()
                }
                .buttonStyle(.bordered)
                .tint(AppColors.coral)
            }

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
    }
}

// MARK: - TripDayCard

private struct TripDayCard: View {
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
                HStack(alignment: .top, spacing: SpacingTokens.small) {
                    VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                        Text(self.day.displayLabel)
                            .font(TypographyTokens.sectionHeader)
                            .bold()

                        if let dateLabel = self.day.dateLabel {
                            Text(dateLabel)
                                .font(TypographyTokens.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

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

// MARK: - TripsInlineCount

private struct TripsInlineCount: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)

            Text(self.value)
                .font(TypographyTokens.footnote.monospacedDigit())
                .bold()
                .foregroundStyle(self.tint)
        }
        .padding(.vertical, SpacingTokens.xxSmall)
        .padding(.horizontal, SpacingTokens.xSmall)
        .background(self.tint.opacity(0.10), in: .rect(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - TripActivityRow

private struct TripActivityRow: View {
    let activity: TripActivity
    let onEdit: () -> Void
    let onCycleStatus: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.small) {
            Button("Update Status", systemImage: self.activity.activityStatus.systemImage) {
                self.onCycleStatus()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(self.activity.activityStatus.color)

            Button {
                self.onEdit()
            } label: {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    HStack(spacing: SpacingTokens.xSmall) {
                        Label(self.activity.type.label, systemImage: self.activity.type.systemImage)
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

                    if let notes = activity.notes, !notes.isEmpty {
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
        .background(AppColors.surfaceSecondary.opacity(0.75), in: .rect(cornerRadius: 18, style: .continuous))
    }
}
