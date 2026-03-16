import SwiftData
import SwiftUI

// MARK: - TripsView

struct TripsView: View {
    @Query(sort: \Trip.dateCreated, order: .reverse)
    private var trips: [Trip]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = TripsViewModel()
    @State private var tripPendingDeletion: Trip?
    @State private var errorMessage: String?

    private var sections: [TripsViewModel.TripSection] {
        self.viewModel.filteredSections(from: self.trips)
    }

    private var visibleTripCount: Int {
        self.sections.reduce(0) { partialResult, section in
            partialResult + section.trips.count
        }
    }

    var body: some View {
        ScrollView {
            if self.trips.isEmpty, self.viewModel.searchText.isEmpty {
                TripsEmptyState(
                    onCreateTrip: {
                        self.viewModel.isAddTripSheetPresented = true
                    },
                    onRestoreSamples: self.restoreSampleTrips
                )
                .padding(.top, SpacingTokens.xxLarge)
            } else if self.sections.isEmpty {
                TripsNoResults(
                    searchText: self.viewModel.searchText,
                    selectedStatusFilter: self.viewModel.selectedStatusFilter
                )
                .padding(.top, SpacingTokens.xxLarge)
            } else {
                TripsContent(
                    allTrips: self.trips,
                    sections: self.sections,
                    viewModel: self.viewModel,
                    onEditTrip: { trip in
                        self.viewModel.tripToEdit = trip
                    },
                    onDeleteTrip: { trip in
                        self.tripPendingDeletion = trip
                    }
                )
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle("Trips")
        .searchable(
            text: self.$viewModel.searchText,
            placement: .toolbar,
            prompt: "Search trips, cities, or countries"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TripsFilterMenu(selectedFilter: self.$viewModel.selectedStatusFilter)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Trip", systemImage: "plus") {
                    self.viewModel.isAddTripSheetPresented = true
                }
            }
        }
        .sheet(isPresented: self.$viewModel.isAddTripSheetPresented) {
            AddEditTripView()
        }
        .sheet(item: self.$viewModel.tripToEdit) { trip in
            AddEditTripView(trip: trip)
        }
        .confirmationDialog(
            "Delete Trip",
            isPresented: self.tripDeleteDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) {
                self.confirmDeleteTrip()
            }

            Button("Cancel", role: .cancel) {
                self.tripPendingDeletion = nil
            }
        } message: {
            Text("Deleting a trip also removes its days and activities.")
        }
        .alert(
            "Couldn't Complete Request",
            isPresented: self.errorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.errorMessage ?? "Please try again.")
        }
        .overlay(alignment: .bottomTrailing) {
            if self.visibleTripCount > 0 {
                Button("Create Trip", systemImage: "plus") {
                    self.viewModel.isAddTripSheetPresented = true
                }
                .labelStyle(.iconOnly)
                .padding(SpacingTokens.medium)
                .background(AppGradients.hero(for: self.colorScheme), in: Circle())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
                .padding(.trailing, SpacingTokens.medium)
                .padding(.bottom, SpacingTokens.medium)
                .accessibilityLabel("Create trip")
            }
        }
    }

    private var tripDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { self.tripPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    self.tripPendingDeletion = nil
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

    private func confirmDeleteTrip() {
        guard let tripPendingDeletion else { return }

        do {
            self.modelContext.delete(tripPendingDeletion)
            if self.modelContext.hasChanges {
                try self.modelContext.save()
            }
            self.tripPendingDeletion = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func restoreSampleTrips() {
        do {
            try TripSeedService.seedIfNeeded(in: self.modelContext)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - TripsContent

private struct TripsContent: View {
    let allTrips: [Trip]
    let sections: [TripsViewModel.TripSection]
    let viewModel: TripsViewModel
    let onEditTrip: (Trip) -> Void
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: SpacingTokens.large) {
            TripsSummaryCard(trips: self.allTrips, visibleTripCount: self.visibleTripCount)

            ForEach(self.sections) { section in
                TripSectionView(
                    section: section,
                    viewModel: self.viewModel,
                    onEditTrip: self.onEditTrip,
                    onDeleteTrip: self.onDeleteTrip
                )
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
    }

    private var visibleTripCount: Int {
        self.sections.reduce(0) { partialResult, section in
            partialResult + section.trips.count
        }
    }
}

// MARK: - TripsSummaryCard

private struct TripsSummaryCard: View {
    let trips: [Trip]
    let visibleTripCount: Int

    private var sampleTripCount: Int {
        self.trips.filter(\.isSample).count
    }

    private var plannedActivityCount: Int {
        self.trips.reduce(0) { partialResult, trip in
            partialResult + trip.activityCount
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Trips Library")
                        .font(TypographyTokens.songTitle)
                        .bold()
                        .foregroundStyle(.primary)

                    Text("Plan fast, stay flexible, and keep every day as light or detailed as you want.")
                        .font(TypographyTokens.body)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: SpacingTokens.small) {
                    TripsMetricChip(
                        title: "Visible",
                        value: self.visibleTripCount.formatted(.number),
                        tint: AppColors.info,
                        systemImage: "map"
                    )
                    TripsMetricChip(
                        title: "Samples",
                        value: self.sampleTripCount.formatted(.number),
                        tint: AppColors.gold,
                        systemImage: "sparkles"
                    )
                    TripsMetricChip(
                        title: "Activities",
                        value: self.plannedActivityCount.formatted(.number),
                        tint: AppColors.coral,
                        systemImage: "list.bullet"
                    )
                }
            }
        }
    }
}

// MARK: - TripsMetricChip

struct TripsMetricChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Label(self.title, systemImage: self.systemImage)
                .font(TypographyTokens.footnote)
                .foregroundStyle(self.tint)

            Text(self.value)
                .font(TypographyTokens.cardLabel.monospacedDigit())
                .bold()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(self.tint.opacity(0.12), in: .rect(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - TripSectionView

private struct TripSectionView: View {
    let section: TripsViewModel.TripSection
    let viewModel: TripsViewModel
    let onEditTrip: (Trip) -> Void
    let onDeleteTrip: (Trip) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            HStack(spacing: SpacingTokens.xSmall) {
                Image(systemName: self.section.status.systemImage)
                    .foregroundStyle(self.section.status.color)

                Text(self.section.status.label)
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(.primary)

                Spacer()

                Text(self.section.trips.count, format: .number)
                    .font(TypographyTokens.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ForEach(self.section.trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    TripOverviewCard(
                        trip: trip,
                        cityModel: self.viewModel.cityModel(for: trip),
                        countryFlag: self.viewModel.countryFlag(for: trip)
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        self.onDeleteTrip(trip)
                    }

                    Button("Edit", systemImage: "pencil") {
                        self.onEditTrip(trip)
                    }
                    .tint(AppColors.info)
                }
            }
        }
    }
}

// MARK: - TripOverviewCard

private struct TripOverviewCard: View {
    let trip: Trip
    let cityModel: CityModel?
    let countryFlag: String

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title3) private var cardHeight = 214.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TripOverviewCardBackground(cityModel: self.cityModel)

            LinearGradient(
                colors: [
                    .black.opacity(0.10),
                    .black.opacity(0.28),
                    .black.opacity(0.82)
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
                            title: "Sample",
                            systemImage: "sparkles",
                            tint: AppColors.gold
                        )
                    }

                    Spacer()
                }

                Spacer(minLength: SpacingTokens.medium)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.trip.name)
                        .font(TypographyTokens.songTitle)
                        .bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("\(self.countryFlag) \(self.trip.displayLocation)")
                        .font(TypographyTokens.artistName)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)

                    if let dateRangeLabel = self.trip.dateRangeLabel {
                        Label(dateRangeLabel, systemImage: "calendar")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.white.opacity(0.84))
                    }
                }

                HStack(spacing: SpacingTokens.small) {
                    TripsFootnotePill(
                        title: self.trip.scheduleSummaryLabel,
                        systemImage: "list.bullet.rectangle"
                    )

                    if let progressLabel = self.trip.progressLabel {
                        TripsFootnotePill(
                            title: progressLabel,
                            systemImage: "checkmark.circle"
                        )
                    }
                }
            }
            .padding(SpacingTokens.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.cardHeight)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
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
        .contentShape(.rect(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
    }

    private var accessibilityLabel: String {
        [
            self.trip.name,
            self.trip.displayLocation,
            self.trip.status.label,
            self.trip.scheduleSummaryLabel,
            self.trip.progressLabel
        ]
        .compactMap(\.self)
        .joined(separator: ", ")
    }
}

// MARK: - TripOverviewCardBackground

private struct TripOverviewCardBackground: View {
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
                        AppColors.info.opacity(0.92),
                        AppColors.violet.opacity(0.86),
                        AppColors.coral.opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.22))
                }
            }
        }
    }
}

// MARK: - TripsBadge

struct TripsBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(TypographyTokens.footnote)
            .foregroundStyle(.white)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(self.tint.opacity(0.72), in: Capsule())
    }
}

// MARK: - TripsFootnotePill

struct TripsFootnotePill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(TypographyTokens.footnote)
            .foregroundStyle(.white)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(.thinMaterial, in: Capsule())
    }
}

// MARK: - TripsFilterMenu

private struct TripsFilterMenu: View {
    @Binding var selectedFilter: TripStatus?

    var body: some View {
        Menu {
            Button("All", systemImage: self.selectedFilter == nil ? "checkmark" : "line.3.horizontal.decrease.circle") {
                self.selectedFilter = nil
            }

            ForEach(TripStatus.allCases) { status in
                Button(
                    status.label,
                    systemImage: self.selectedFilter == status ? "checkmark" : status.systemImage
                ) {
                    self.selectedFilter = status
                }
            }
        } label: {
            Image(
                systemName: self.selectedFilter == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
            .symbolEffect(.bounce, value: self.selectedFilter)
        }
        .accessibilityLabel("Filter trips")
    }
}

// MARK: - TripsEmptyState

private struct TripsEmptyState: View {
    let onCreateTrip: () -> Void
    let onRestoreSamples: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.large) {
            Image(systemName: "suitcase.rolling.fill")
                .font(.system(size: 62))
                .foregroundStyle(AppColors.coral.opacity(0.72))
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: SpacingTokens.xSmall) {
                Text("Plan Trips Your Way")
                    .font(TypographyTokens.songTitle)
                    .bold()
                    .foregroundStyle(.primary)

                Text(
                    "Keep rough sketches, detailed day plans, or both. Start with your own trip or load the sample itineraries."
                )
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            }

            VStack(spacing: SpacingTokens.small) {
                Button("Create Trip", systemImage: "plus") {
                    self.onCreateTrip()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.coral)

                Button("Load Sample Trips", systemImage: "sparkles") {
                    self.onRestoreSamples()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: SpacingTokens.xSmall) {
                TripsSampleNamePill(title: "Trinidad and Tobago")
                TripsSampleNamePill(title: "Vancouver, BC")
                TripsSampleNamePill(title: "San Francisco")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }
}

// MARK: - TripsSampleNamePill

private struct TripsSampleNamePill: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(TypographyTokens.footnote)
            .foregroundStyle(.secondary)
            .padding(.vertical, SpacingTokens.xxSmall)
            .padding(.horizontal, SpacingTokens.xSmall)
            .background(AppColors.surfaceSecondary, in: Capsule())
    }
}

// MARK: - TripsNoResults

private struct TripsNoResults: View {
    let searchText: String
    let selectedStatusFilter: TripStatus?

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(self.message)
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }

    private var message: String {
        if let selectedStatusFilter, self.searchText.isEmpty {
            return "No \(selectedStatusFilter.label.lowercased()) trips yet."
        }

        if let selectedStatusFilter {
            return "No \(selectedStatusFilter.label.lowercased()) trips match \"\(self.searchText)\"."
        }

        return "No trips match \"\(self.searchText)\"."
    }
}
