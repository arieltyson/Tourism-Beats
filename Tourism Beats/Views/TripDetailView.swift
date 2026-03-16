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
            TripDetailContent(
                trip: self.trip,
                cityModel: self.viewModel.cityModel(for: self.trip),
                countryFlag: self.viewModel.countryFlag(for: self.trip),
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
            .padding(.vertical, SpacingTokens.small)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, SpacingTokens.medium, for: .scrollContent)
        .contentMargins(.bottom, SpacingTokens.xxLarge, for: .scrollContent)
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

// MARK: - TripDetailContent

private struct TripDetailContent: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String
    let onAddDay: () -> Void
    let onAddActivity: (TripDay) -> Void
    let onEditActivity: (TripActivity) -> Void
    let onCycleActivityStatus: (TripActivity) -> Void
    let onDeleteActivity: (TripActivity) -> Void
    let onDeleteDay: (TripDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            TripHeroCard(
                trip: self.trip,
                cityModel: self.cityModel,
                countryFlag: self.countryFlag
            )

            TripSummaryCard(trip: self.trip)

            if let notes = self.trip.notesSummary {
                TripNotesCard(notes: notes)
            }

            TripItinerarySection(
                trip: self.trip,
                onAddDay: self.onAddDay,
                onAddActivity: self.onAddActivity,
                onEditActivity: self.onEditActivity,
                onCycleActivityStatus: self.onCycleActivityStatus,
                onDeleteActivity: self.onDeleteActivity,
                onDeleteDay: self.onDeleteDay
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                TripHeroBadgeLayout(trip: self.trip)

                Spacer(minLength: SpacingTokens.large)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.trip.name)
                        .font(TypographyTokens.heroTitle)
                        .bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)

                    Text("\(self.countryFlag) \(self.trip.displayLocation)")
                        .font(TypographyTokens.songTitle)
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let dateRangeLabel = self.trip.dateRangeLabel {
                        Label(dateRangeLabel, systemImage: "calendar")
                            .font(TypographyTokens.body)
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                TripHeroFootnoteLayout(trip: self.trip)
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

// MARK: - TripHeroBadgeLayout

private struct TripHeroBadgeLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.xSmall) {
                TripHeroStatusBadges(trip: self.trip)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripHeroStatusBadges(trip: self.trip)
            }
        }
    }
}

// MARK: - TripHeroStatusBadges

private struct TripHeroStatusBadges: View {
    let trip: Trip

    var body: some View {
        Group {
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
    }
}

// MARK: - TripHeroFootnoteLayout

private struct TripHeroFootnoteLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.small) {
                TripHeroFootnotePills(trip: self.trip)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                TripHeroFootnotePills(trip: self.trip)
            }
        }
    }
}

// MARK: - TripHeroFootnotePills

private struct TripHeroFootnotePills: View {
    let trip: Trip

    var body: some View {
        Group {
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
