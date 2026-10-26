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
    @State private var scrollTargetDayID: PersistentIdentifier?
    @State private var suggestionRequest: TripSuggestionRequest?
    @State private var addedSuggestionCount = 0

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                TripDetailContent(
                    trip: self.trip,
                    cityModel: self.cityModel,
                    countryFlag: self.viewModel.countryFlag(for: self.trip),
                    onAddDay: self.addDay,
                    onSuggest: self.cityModel.map { city in
                        { scope in
                            self.suggestionRequest = TripSuggestionRequest(city: city, scope: scope)
                        }
                    },
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
            .onChange(of: self.scrollTargetDayID) { _, targetID in
                guard let targetID else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation(AnimationTokens.standard) {
                        scrollProxy.scrollTo(targetID, anchor: .bottom)
                    }
                }
                self.scrollTargetDayID = nil
            }
        }
        .navigationTitle(self.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add Day", systemImage: "plus") {
                    self.addDay()
                }
                .labelStyle(.iconOnly)
                .accessibilityInputLabels(["Add Day", "Create Day"])

                Menu {
                    if let cityModel = self.cityModel {
                        Button("Suggest Activities", systemImage: "sparkles") {
                            self.suggestionRequest = TripSuggestionRequest(city: cityModel, scope: .trip)
                        }
                    }

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
                .accessibilityInputLabels(["Trip Actions", "More Trip Actions"])
            }
        }
        .sheet(isPresented: self.$isEditTripPresented) {
            AddEditTripView(trip: self.trip)
        }
        .sheet(item: self.$suggestionRequest) { request in
            TripSuggestionsView(
                trip: self.trip,
                city: request.city,
                scope: request.scope,
                onApplied: self.suggestionsApplied
            )
        }
        .sensoryFeedback(.success, trigger: self.addedSuggestionCount)
        .task(id: self.cityModel?.id) {
            guard let cityModel = self.cityModel else { return }
            await TripSuggestionsViewModel.prefetchGuides(for: cityModel)
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
        .alert(
            "Delete Day",
            isPresented: self.dayDeleteDialogPresented
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

    private var cityModel: CityModel? {
        self.viewModel.cityModel(for: self.trip)
    }

    private func suggestionsApplied(_ addedCount: Int) {
        guard addedCount > 0 else { return }
        self.addedSuggestionCount += addedCount
        AccessibilityAnnouncer.announceActivitiesAdded(count: addedCount)
    }

    private func addDay() {
        let newDay = TripDay(
            dayNumber: self.trip.nextDayNumber,
            date: self.trip.nextDayDate,
            trip: self.trip
        )
        self.modelContext.insert(newDay)
        self.trip.alignScheduleWithDays()
        self.persistChanges()
        self.scrollTargetDayID = newDay.persistentModelID
    }

    private func confirmDeleteDay() {
        guard let dayPendingDeletion else { return }
        self.trip.days?.removeAll { $0 == dayPendingDeletion }
        self.modelContext.delete(dayPendingDeletion)
        self.trip.alignScheduleWithDays()
        self.persistChanges()
        self.dayPendingDeletion = nil
    }

    private func confirmDeleteTrip() {
        self.isTripDeleteConfirmationPresented = false

        do {
            try TripSeedService.deleteTrip(self.trip, in: self.modelContext)

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
