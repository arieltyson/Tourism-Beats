import SwiftData
import SwiftUI

// MARK: - TripsView

struct TripsView: View {
    @Query(sort: \Trip.dateCreated, order: .reverse)
    private var trips: [Trip]

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

    private var shouldOfferSampleTrips: Bool {
        !self.trips.contains(where: { !$0.isSample })
    }

    var body: some View {
        Group {
            if self.presentedTrips.isEmpty, self.viewModel.searchText.isEmpty {
                ScrollView {
                    TripsEmptyState(
                        showsSampleTrips: self.shouldOfferSampleTrips,
                        onCreateTrip: {
                            self.viewModel.isAddTripSheetPresented = true
                        },
                        onRestoreSamples: self.restoreSampleTrips
                    )
                    .padding(.top, SpacingTokens.xxLarge)
                }
            } else if self.sections.isEmpty {
                ScrollView {
                    TripsNoResults(
                        searchText: self.viewModel.searchText,
                        selectedStatusFilter: self.viewModel.selectedStatusFilter
                    )
                    .padding(.top, SpacingTokens.xxLarge)
                }
            } else {
                // A list, not a scroll view, so swiping a card to delete it
                // behaves as it does everywhere else in iOS: one card open at
                // a time, and closed again once its button is tapped.
                TripsContent(
                    sections: self.sections,
                    viewModel: self.viewModel,
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
                .accessibilityInputLabels(["Add Trip", "Create Trip", "New Trip"])
            }
        }
        .sheet(isPresented: self.$viewModel.isAddTripSheetPresented) {
            AddEditTripView()
        }
        .alert(
            self.tripPendingDeletion.map { "Delete “\($0.name)”?" } ?? "Delete Trip?",
            isPresented: self.tripDeleteDialogPresented,
            presenting: self.tripPendingDeletion
        ) { _ in
            Button("Delete", role: .destructive) {
                self.confirmDeleteTrip()
            }

            Button("Cancel", role: .cancel) {
                self.tripPendingDeletion = nil
            }
        } message: { _ in
            Text("Its days and activities will be deleted too.")
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
