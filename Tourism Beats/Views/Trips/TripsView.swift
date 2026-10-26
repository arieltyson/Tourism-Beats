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

    private var presentedTrips: [Trip] {
        self.viewModel.presentedTrips(from: self.trips)
    }

    private var sections: [TripsViewModel.TripSection] {
        self.viewModel.filteredSections(from: self.presentedTrips)
    }

    private var visibleTripCount: Int {
        self.sections.reduce(0) { partialResult, section in
            partialResult + section.trips.count
        }
    }

    private var shouldOfferSampleTrips: Bool {
        !self.trips.contains(where: { !$0.isSample })
    }

    var body: some View {
        ScrollView {
            if self.presentedTrips.isEmpty, self.viewModel.searchText.isEmpty {
                TripsEmptyState(
                    showsSampleTrips: self.shouldOfferSampleTrips,
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
                .foregroundStyle(AppColors.onImagePrimary)
                .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
                .padding(.trailing, SpacingTokens.medium)
                .padding(.bottom, SpacingTokens.medium)
                .accessibilityLabel("Create trip")
                .accessibilityInputLabels(["Create Trip", "Add Trip"])
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
            try TripSeedService.deleteTrip(
                tripPendingDeletion,
                in: self.modelContext
            )
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
